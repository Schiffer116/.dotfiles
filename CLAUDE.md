# CLAUDE.md

Only what the code doesn't show. Read the code for everything else.

## Nix and the live configs

- home-manager links configs back into this checkout (`mkOutOfStoreSymlink`), so editing a config here changes the live one immediately. Its location is set once, in the `link` helper in `nix/home.nix`. Only `.nix` changes need `home-manager switch --flake .#schiffer@archlinux`.
- Flakes see only files tracked by git, so `git add` new files before building.
- pacman installs, not Nix:
  - the compositor;
  - GUI apps (Nix's GL breaks outside NixOS);
  - anything needing udev rules, setuid or PAM.
- `system/` files are copied into `/etc` with sudo, never symlinked. logind and other system daemons run with `ProtectHome=yes` and silently ignore links into `~/.dotfiles`.
- LSP servers come from `nix/home/editor.nix`, not Mason.
- Colours come only from `nix/home/theme.nix` (terms in `GLOSSARY.md`). A raw hex or `rgba()` literal in a config is a bug.

## Claude Code config

- `.claude/CLAUDE.md` is the user's global instructions for every project, not guidance for this repo.
- Claude Code rewrites `~/.claude/settings.json` (a link into this repo), so its changes show up in `git diff`. Commit or revert them deliberately.
- Settings for one repo only, such as auto-mode trust facts, go in that repo's `.claude/settings.local.json`.

## Desktop

- Open and close eww windows only through `scripts/eww-windows.sh`. A plain `eww open` that fails starts a second daemon, and the bar variables then split between the two daemons.
- Address screens by connector name, never by index: GDK renumbers monitors when eDP-1 is disabled and re-enabled.
- `.config/hypr/monitors.lua` is the only place that names outputs.
- hypridle (started by `hyprland.lua`) locks with hyprlock before sleep and after idle; `loginctl lock-session` is the one way to lock. After idle, `scripts/dpms.sh` turns outputs on/off and keeps the internal panel off while the lid is closed.
- Closing the lid never suspends: the laptop doubles as a headless server.
- A widget directory with a `CONTEXT.md` defines domain terms. Read it before changing the widget and keep it in sync.
- `eww logs` follows forever, so read `~/.cache/eww/eww_*.log` instead. After `hyprctl reload`, check `hyprctl configerrors`.
- There's no CI. Shellcheck the scripts you touch, run the `*.test.sh` next to any jq plan you change, and verify on the live desktop.
