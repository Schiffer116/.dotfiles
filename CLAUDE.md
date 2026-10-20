# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## How configs reach `$HOME`

The repo lives at `~/.dotfiles` (required: the Nix links hardcode that path). home-manager (`flake.nix`, `nix/`) links every config file into `$HOME`; a new path gets a `config.lib.dotfiles.link` entry in a `nix/home/*.nix` module. The machine is one Arch laptop:

- Dev environment: zsh, nvim, starship, tmux, herdr, and all of Claude Code's config under `.claude/` (the list is in `nix/home/agents.nix`). `.claude/CLAUDE.md` is the user's global agent instructions for every project, not guidance for this repo. It also installs the CLI tools, toolchains and the LSP servers/formatters nvim uses.
- Desktop (`nix/home/desktop.nix`): Hyprland, eww, mako, kitty, `scripts/`, `Pictures/`, `levelctl` and the Wayland CLI tools the scripts call. pacman keeps the compositor, GUI apps (Nix GUI apps break on GL outside NixOS), tools needing udev rules, setuid or PAM (brightnessctl, ddcutil, swaylock), and system services; desktop daemons start from `hyprland.lua`.

`system/` holds the few `/etc` files the laptop needs (e.g. `system/logind.conf.d/lid.conf`); home-manager cannot write `/etc`, so each is copied in by hand with sudo, as its header comment says. Copy, never symlink: system daemons like logind run with `ProtectHome=yes` and silently ignore a link into `~/.dotfiles`.

The links point back into the repo (`mkOutOfStoreSymlink`, see `nix/home.nix`), so editing a config file here edits the live config with no rebuild. A rebuild is only needed after changing `.nix` files. When Claude Code rewrites `~/.claude/settings.json` (`/config`, permission grants) the change appears in `git diff` here; commit or revert it deliberately. That file is shared by every project: repo-specific settings such as auto-mode trust facts belong in that repo's `.claude/settings.local.json`. Status line logic lives in `.claude/statusline.sh`, not inline in the JSON. Spoken alerts are a skill, not a hook: `.claude/skills/notify-user/` (the agent calls it when it needs the user; `DRY_RUN=1` previews `speak.sh`).

## Nix layout

`flake.nix` has one output, `homeConfigurations."schiffer@archlinux"`: standalone home-manager whose entry `nix/home.nix` holds identity, XDG and the `link` helper, and imports one module per topic from `nix/home/` (shell, editor, agents, cli, dev, desktop).

LSP servers come from Nix (`nix/home/editor.nix`), not Mason. Add new servers there.

Flakes only see files tracked by git: `git add` new files before building.

## Commands

- Dev tools for this repo (nil, nixfmt, shellcheck): `nix develop`
- Format Nix: `nix fmt`. Check the flake evaluates: `nix flake check`
- Apply on the laptop: `home-manager switch --flake ~/.dotfiles#schiffer@archlinux` (`home-manager build --flake ...` to test without activating)
- eww: `eww reload`, `eww get <var>`; `eww logs` follows forever, so agents read `~/.cache/eww/eww_*.log` instead. Hyprland: `hyprctl reload`, then `hyprctl configerrors`

There is no test suite or CI. Shellcheck scripts you touch and verify changes on the live desktop.

## Desktop architecture (Hyprland + eww)

The pieces talk through shell scripts and eww variables, so a change usually spans several files:

- `.config/hypr/hyprland.lua` is a Lua config (`hl.*` API, not `hyprland.conf`). It autostarts daemons and binds keys to scripts by bare name (`powermenu.sh open`), which works because `~/scripts` is on `PATH` (`.zshenv`).
- Scripts push state into eww with `eww update var=...`. `hypr_ipc.sh` listens on Hyprland's event socket and keeps workspace/window variables in sync.
- `.config/hypr/monitors.lua` (the monitor table) is the only place that names outputs: mode, workspace base, bar window id, other eww windows, brightness backend. `hyprland.lua` builds output rules, workspace rules and workspace keybinds from it and writes it to `$XDG_RUNTIME_DIR/monitors.json` for scripts. An unlisted output gets the next workspace base and a bar.
- `scripts/eww-windows.sh` owns the eww daemon and is the only thing that opens or closes eww windows: `sync` (Hyprland runs it at login and on every output change) matches each output's windows to the enabled outputs, and popups go through `open <window> --focused|--all|--screen <out>`, `close` and `toggle`, with id `<window>@<output>`. Never call `eww open`/`close` directly: a failing plain `eww open` starts a second daemon and the bar variables split between them. The plan is pure jq in `scripts/eww-windows.jq` (`bash scripts/eww-windows.test.sh`).
- Closing the lid never suspends (logind ignores it). `hyprland.lua` disables the internal panel when another output is connected, or turns it DPMS off when not; the window sync follows.
- `.config/eww/eww.yuck` only `include`s one subdirectory per widget, each with its own `.yuck`/`.scss`. Windows pick screens by connector name (`--screen <name>` from the window sync), never by index: GDK renumbers monitors when eDP-1 is disabled and re-enabled. Widgets read data via `defpoll`/`deflisten` on scripts. Some widget directories carry a `CONTEXT.md` domain glossary (e.g. `finance/` defines payday and liquid assets): read it before changing the widget and keep it in sync.
- `scripts/picker.sh` is the one keyboard picker (SUPER+D apps, SUPER+V clipboard): state in `$XDG_RUNTIME_DIR/picker.json`, paging as pure jq in `scripts/picker.jq` (`bash scripts/picker.test.sh`), one eww variable `picker` rendered by `.config/eww/picker/`. A new list is a `<name>_list` / `<name>_select` adapter pair in the script.
- Volume and brightness go through `levelctl` (`scripts/levelctl`, Go, built by Nix in `nix/home/desktop.nix`; `go test ./...` there). Keybinds and eww call `levelctl volume|brightness +N|-N`; the bar reads one `deflisten levels` from `levelctl watch`. Brightness backends per output come from the monitor table; volume follows external changes via `pactl subscribe`, and outputs are read on Hyprland's `monitoradded`/`monitorremoved` events with backoff retries (DDC answers late after login or hotplug).
