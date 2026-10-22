# The Palette: Catppuccin Mocha with crust as the main background (see GLOSSARY.md). The one
# place colours are written down. Small colour-only files per format land in ~/.config/theme/;
# eww, Hyprland, kitty, tmux and the scripts include them. Apps with an official Catppuccin
# theme (nvim, herdr, mako) use it unchanged and are not generated from here.
{ lib, ... }:
let
  palette = {
    rosewater = "f5e0dc";
    flamingo = "f2cdcd";
    pink = "f5c2e7";
    mauve = "cba6f7";
    red = "f38ba8";
    maroon = "eba0ac";
    peach = "fab387";
    yellow = "f9e2af";
    green = "a6e3a1";
    teal = "94e2d5";
    sky = "89dceb";
    sapphire = "74c7ec";
    blue = "89b4fa";
    lavender = "b4befe";
    text = "cdd6f4";
    subtext1 = "bac2de";
    subtext0 = "a6adc8";
    overlay2 = "9399b2";
    overlay1 = "7f849c";
    overlay0 = "6c7086";
    surface2 = "585b70";
    surface1 = "45475a";
    surface0 = "313244";
    base = "1e1e2e";
    mantle = "181825";
    crust = "11111b";
  };

  # Roles name a palette colour by its job.
  roles = {
    bg = "crust";
    surface = "base";
    text = "text";
    accent = "lavender";
    ok = "green";
    warn = "yellow";
    urgent = "red";
  };

  # Every name a config can use, mapped to its hex (no #). A role named like a palette colour
  # (text) is the same colour.
  colours = palette // lib.mapAttrs (_: name: palette.${name}) roles;

  each = f: lib.concatStringsSep "\n" (lib.mapAttrsToList f colours) + "\n";
  at = name: "#${colours.${name}}";
in
{
  xdg.configFile = {
    # Sass: $name, used as $accent or rgba($accent, 0.5).
    "theme/palette.scss".text = each (n: v: "$" + "${n}: #${v};");

    # CSS custom properties: var(--accent). Berthier's Console serves this as /theme.css.
    "theme/palette.css".text = ":root {\n" + each (n: v: "  --${n}: #${v};") + "}\n";

    # eww: (defvar theme-<name> "#hex"), for styles built in yuck.
    "theme/palette.yuck".text = each (n: v: ''(defvar theme-${n} "#${v}")'');

    # Lua: a table of bare hex strings. hyprland.lua turns them into rgba().
    "theme/palette.lua".text = "return {\n" + each (n: v: "  ${n} = '${v}',") + "}\n";

    # POSIX sh: theme_<name>="#hex".
    "theme/palette.sh".text = each (n: v: ''theme_${n}="#${v}"'');

    "theme/kitty.conf".text = ''
      foreground ${at "text"}
      background ${at "bg"}
      selection_foreground ${at "bg"}
      selection_background ${at "accent"}
      cursor ${at "accent"}
      cursor_text_color ${at "bg"}
      url_color ${at "sapphire"}
      active_border_color ${at "accent"}
      inactive_border_color ${at "surface1"}
      bell_border_color ${at "warn"}
      active_tab_foreground ${at "bg"}
      active_tab_background ${at "accent"}
      inactive_tab_foreground ${at "text"}
      inactive_tab_background ${at "surface"}
      tab_bar_background ${at "bg"}
      tab_bar_margin_color ${at "bg"}
      mark1_foreground ${at "bg"}
      mark1_background ${at "accent"}
      mark2_foreground ${at "bg"}
      mark2_background ${at "mauve"}
      mark3_foreground ${at "bg"}
      mark3_background ${at "sapphire"}
      color0 ${at "surface1"}
      color8 ${at "surface2"}
      color1 ${at "red"}
      color9 ${at "red"}
      color2 ${at "green"}
      color10 ${at "green"}
      color3 ${at "yellow"}
      color11 ${at "yellow"}
      color4 ${at "blue"}
      color12 ${at "blue"}
      color5 ${at "pink"}
      color13 ${at "pink"}
      color6 ${at "teal"}
      color14 ${at "teal"}
      color7 ${at "subtext1"}
      color15 ${at "subtext0"}
    '';

    # hyprlang: $name = rgb(hex), and $name_dim = the same at ~half alpha, for `source =`.
    "theme/hyprlock.conf".text = each (
      n: v: "$" + "${n} = rgb(${v})\n" + "$" + "${n}_dim = rgba(${v}88)"
    );

    # tmux: every colour as a user option (#{@accent}) for tmux.conf, plus the styles.
    "theme/tmux.conf".text = each (n: v: ''set -g @${n} "#${v}"'') + ''
      set -g status-style "fg=${at "text"},bg=${at "bg"}"
      set -g message-style "fg=${at "bg"},bg=${at "accent"}"
      set -g mode-style "fg=${at "bg"},bg=${at "accent"}"
      set -g pane-border-style "fg=${at "surface"}"
      set -g pane-active-border-style "bg=default,fg=${at "accent"}"
      set -g window-status-style "fg=${at "overlay1"},bg=${at "bg"}"
      set -g window-status-current-style "fg=${at "accent"},bg=${at "bg"},bold"
      set -g window-status-activity-style "fg=${at "warn"},bg=${at "bg"}"
    '';
  };
}
