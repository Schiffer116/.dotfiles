# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## How configs reach `$HOME`

The repo lives at `~/.dotfiles` (required: the Nix links hardcode that path). Two tools link files into place, and each path is owned by exactly one of them:

- **home-manager** (`flake.nix`, `nix/`) owns the dev environment: zsh, nvim, starship, tmux, herdr, Claude Code keybindings/hooks, and `.CLAUDE.md` (linked to `~/.claude/CLAUDE.md`; it is the user's global agent instructions, not guidance for this repo). It also installs the CLI tools, toolchains and the LSP servers/formatters nvim uses.
- **GNU Stow** (`cd ~/.dotfiles && stow .`) owns the desktop: Hyprland, eww, mako, kitty, `scripts/`, `Pictures/`. pacman provides the desktop packages and system services.

`system/` holds the few `/etc` files the laptop needs (e.g. `system/logind.conf.d/lid.conf`); neither tool can write `/etc` there, so each is copied in by hand with sudo, as its header comment says. Copy, never symlink: system daemons like logind run with `ProtectHome=yes` and silently ignore a link into `~/.dotfiles`.

`.stow-local-ignore` is what keeps the two apart: every home-manager-owned path, and every repo-only file (this one, `nix/`, `infra/`), must be listed there or stow will link it into `$HOME` too. Moving a path to home-manager means adding a `config.lib.dotfiles.link` entry in a `nix/home/*.nix` module and a stow-ignore entry.

Both use symlinks back into the repo (home-manager via `mkOutOfStoreSymlink`, see `nix/home/common.nix`), so editing a config file here edits the live config with no rebuild. A rebuild is only needed after changing `.nix` files. `.claude/settings.json` is stow-linked, so when Claude Code rewrites its settings (`/config`, permission grants) the change appears in `git diff` here; commit or revert it deliberately.

## Nix layout

`flake.nix` has two machines sharing the `nix/home/*.nix` modules:

- `homeConfigurations."schiffer@archlinux"`: the Arch laptop, standalone home-manager (`nix/hosts/laptop.nix`).
- `nixosConfigurations.aws-dev`: a headless NixOS dev box on EC2, reached only over Tailscale, that powers itself off when idle (`nix/hosts/aws-dev/`). The AWS side is Terraform in `infra/aws-dev/`, whose README covers deploy, daily use and the idle-stop rules.

LSP servers come from Nix (`nix/home/editor.nix`), not Mason, because Mason binaries do not run on NixOS. Add new servers there.

Flakes only see files tracked by git: `git add` new files before building.

## Commands

- Dev tools for this repo (nil, nixfmt, terraform, shellcheck, awscli): `nix develop`
- Format Nix: `nix fmt`. Check the flake evaluates: `nix flake check`
- Apply on the laptop: `home-manager switch --flake ~/.dotfiles#schiffer@archlinux` (`home-manager build --flake ...` to test without activating)
- Build the box config locally without deploying: `nix build .#nixosConfigurations.aws-dev.config.system.build.toplevel`. Deploying happens on the box: `sudo nixos-rebuild switch --flake ~/.dotfiles#aws-dev`
- Terraform: `terraform fmt -check && terraform validate` in `infra/aws-dev`. `apply` creates billable resources.
- Dev box power: `scripts/devbox.sh start|stop|status`
- Idle-stop logic: `DRY_RUN=1 STATE_DIR=<tmpdir> bash nix/hosts/aws-dev/idle-stop.sh` (other inputs like `FLEET_HOME` and `PROC_STAT` are env-overridable too)
- Stow: `stow -n -v .` is a safe dry run before `stow .`
- eww: `eww reload`, `eww logs`, `eww get <var>`. Hyprland: `hyprctl reload`, then `hyprctl configerrors`

There is no test suite or CI. Shellcheck scripts you touch and verify changes on the live desktop.

## Desktop architecture (Hyprland + eww)

The pieces talk through shell scripts and eww variables, so a change usually spans several files:

- `.config/hypr/hyprland.lua` is a Lua config (`hl.*` API, not `hyprland.conf`). It autostarts daemons and binds keys to scripts by bare name (`powermenu.sh open`), which works because `~/scripts` is on `PATH` (`.zshenv`).
- Scripts push state into eww with `eww update var=...`. `hypr_ipc.sh` listens on Hyprland's event socket and keeps workspace/window variables in sync.
- `.config/hypr/monitors.lua` (the monitor table) is the only place that names outputs: mode, workspace base, bar window id, other eww windows, brightness backend. `hyprland.lua` builds output rules, workspace rules and workspace keybinds from it and writes it to `$XDG_RUNTIME_DIR/monitors.json` for scripts. An unlisted output gets the next workspace base and a bar.
- `scripts/eww-windows.sh sync` owns the eww daemon and opens/closes each output's windows to match the enabled outputs; Hyprland runs it at login and on every output change. Any other `eww open` must pass `--no-daemonize`: a failing plain `eww open` starts a second daemon and the bar variables split between them.
- Closing the lid never suspends (logind ignores it). `hyprland.lua` disables the internal panel when another output is connected, or turns it DPMS off when not; the window sync follows.
- `.config/eww/eww.yuck` only `include`s one subdirectory per widget, each with its own `.yuck`/`.scss`. Windows pick screens by connector name (`--screen <name>` from the window sync), never by index: GDK renumbers monitors when eDP-1 is disabled and re-enabled. Widgets read data via `defpoll`/`deflisten` on scripts. Some widget directories carry a `CONTEXT.md` domain glossary (e.g. `finance/` defines payday and liquid assets): read it before changing the widget and keep it in sync.
- `scripts/picker.sh` is the one keyboard picker (SUPER+D apps, SUPER+V clipboard): state in `$XDG_RUNTIME_DIR/picker.json`, paging as pure jq in `scripts/picker.jq` (`bash scripts/picker.test.sh`), one eww variable `picker` rendered by `.config/eww/picker/`. A new list is a `<name>_list` / `<name>_select` adapter pair in the script.
- Volume and brightness go through `levelctl` (`scripts/levelctl`, Go, built by Nix in `nix/hosts/laptop.nix`; `go test ./...` there). Keybinds and eww call `levelctl volume|brightness +N|-N`; the bar reads one `deflisten levels` from `levelctl watch`. Brightness backends per output come from the monitor table; volume follows external changes via `pactl subscribe`.

`.zshenv` and `.config/zsh/.zshrc` run on both the laptop and the box, so guard anything machine-specific (paths, AWS profile, graphical-only plugins) with an existence check, as the existing entries do.
