# aws-dev: the cloud dev box

A headless NixOS instance on EC2 in the Hanoi Local Zone (`ap-southeast-1-han-1a`), m7i.large (2 vCPU, 8 GiB) with a 50 GiB encrypted gp3 root.
It runs the same home-manager modules as the laptop, and the firstmate fleet.

- **Terraform (this directory)** owns the AWS side: a subnet in the zone inside the default VPC, a security group with no inbound TCP, the SSM instance profile, and the instance.
- **The flake** owns everything inside the box: `nix/hosts/aws-dev`, deployed on the box with `sudo nixos-rebuild switch --flake ~/.dotfiles#aws-dev`.
- **Access** is Tailscale only (`ssh aws-dev`). SSM Session Manager is the break-glass path. Nothing listens on the public interface except Tailscale's WireGuard UDP port.
- **Cost control:** a timer on the box powers it off after 30 idle minutes, and EC2 turns that into a stop (see [Idle auto-stop](#idle-auto-stop)). `scripts/devbox.sh start` brings it back.

## One-time AWS setup (account owner)

1. Opt in to the Hanoi Local Zone. This is free but can only be undone through AWS support:
   `aws ec2 modify-availability-zone-group --region ap-southeast-1 --group-name ap-southeast-1-han-1 --opt-in-status opted-in`
2. Create the Terraform state bucket in `ap-southeast-1`: private, versioned, encrypted.
3. Use short-lived credentials (`aws login` / IAM Identity Center) to run Terraform, not static admin keys.
4. Add an AWS Budgets alert for the account.

## First deploy

`terraform apply` creates billable resources.

```sh
cd ~/.dotfiles/infra/aws-dev
terraform init -backend-config="bucket=<state bucket>"
terraform apply \
  -var bootstrap_ssh_cidr="$(curl -fsS https://checkip.amazonaws.com)/32" \
  -var bootstrap_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

The first `nixos-rebuild` needs a direct SSH session, because Tailscale is not on the stock AMI:

```sh
ssh root@<public_ip from the output>
nix-shell -p git --run 'git clone https://github.com/Schiffer116/.dotfiles /home/schiffer/.dotfiles'
NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake /home/schiffer/.dotfiles#aws-dev
chown -R schiffer:users /home/schiffer/.dotfiles
tailscale up --ssh   # approve the login in the browser
```

The rebuild closes port 22 on the public interface, but the open session survives it.
If the session drops before `tailscale up`, finish over SSM instead: `aws ssm start-session --region ap-southeast-1 --target <instance_id>`.

From the laptop, check `ssh aws-dev`. Then close the bootstrap path by running `terraform apply` again without the two `-var` flags.
Optionally, disable key expiry for the node in the Tailscale admin console.

Every later change to the box: edit the flake, push, then on the box run `git -C ~/.dotfiles pull && sudo nixos-rebuild switch --flake ~/.dotfiles#aws-dev`.

### Hanoi or Singapore

From the laptop, `tailscale ping aws-dev` should report a direct path, not DERP.
Keep Hanoi if it is clearly faster than Singapore's ~37 ms.
Otherwise, apply with `-var zone=ap-southeast-1a`. That replaces the instance, and with it `/home`.

## Daily use

```sh
scripts/devbox.sh start    # start, then wait for Tailscale
scripts/devbox.sh status
scripts/devbox.sh stop
ssh aws-dev                # or herdr --remote
```

The public IP changes on every start. Only Tailscale's name is stable.

## Idle auto-stop

`idle-stop.timer` runs every 5 minutes, starting 10 minutes after boot. The box powers off only after 30 consecutive minutes in which all of these held:

- nobody was logged in (no utmp, OpenSSH or Tailscale SSH session),
- no firstmate lane reported `state=busy` in `~/firstmate/state/*.busy-state`, and none reported `state=unknown` within the last 2 hours,
- CPU stayed under 20% of one vCPU, which catches agents and builds that write no busy-state record,
- `~/.config/idle-stop/inhibit` did not exist.

To keep the box up regardless, `touch ~/.config/idle-stop/inhibit`. Remove the file to re-enable the stop.
Each run logs its verdict: `journalctl -u idle-stop`.
The thresholds are in `nix/hosts/aws-dev/idle-stop.nix`.

## Fleet tools (on the box, as schiffer)

The flake provides git, gh, jq, tmux, herdr, node and npm, chromium, docker, and nix-ld for the native binaries below.
These self-updating tools install per user into `~/.local/bin`, which is on `PATH`:

```sh
mkdir -p ~/.local/bin   # the treehouse installer uses it only when it already exists
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
npm install -g gh-axi chrome-devtools-axi lavish-axi tasks-axi quota-axi   # prefix ~/.local (NPM_CONFIG_PREFIX)
gh-axi setup hooks && chrome-devtools-axi setup hooks && lavish-axi setup hooks
```

## Moving the firstmate home to the box

These steps are manual, and no credentials are copied. Each machine logs in on its own.

1. **Log in on the box** (interactive): `gh auth login`, `claude` (then `/login`), and `aws login` if it is needed there.
2. **SSH key for GitHub:** `ssh-keygen -t ed25519`, then `gh ssh-key add ~/.ssh/id_ed25519.pub --title aws-dev`.
3. **Clone firstmate:** `git clone https://github.com/kunchenguid/firstmate ~/firstmate`, then install the [fleet tools](#fleet-tools-on-the-box-as-schiffer).
4. **Quiesce the laptop fleet:** let running lanes finish or pause them, then stop the firstmate session there. Two homes must never supervise the same lanes.
5. **Copy the home's local state over Tailscale**, from the laptop:
   ```sh
   rsync -a ~/firstmate/config/ aws-dev:firstmate/config/
   rsync -a ~/firstmate/data/   aws-dev:firstmate/data/
   rsync -a ~/firstmate/state/  aws-dev:firstmate/state/
   ```
   Skip `projects/`. Re-clone the active projects on the box instead, so the worktrees are recreated there.
6. **Project secrets:** `scp` each project's `.env` from the laptop to the same path on the box over Tailscale. Keep them out of git.
7. **Start firstmate on the box** in a tmux or herdr session (`cd ~/firstmate && claude`), so it survives SSH disconnects. Lingering keeps the user manager running with nobody logged in.

## Teardown

`terraform destroy` removes everything this directory created. The laptop is unaffected.
