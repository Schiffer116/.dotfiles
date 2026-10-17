-- The monitor table: the one place that names outputs. hyprland.lua builds the output rules,
-- workspace rules, lid handling and workspace keybinds from it, and writes it to
-- $XDG_RUNTIME_DIR/monitors.json for eww-windows.sh and levelctl. An output that is not listed
-- here still works: it gets the next free workspace base, a bar, and no brightness control.
--
--   internal        the laptop panel; the lid turns it off or disables it
--   workspace_base  this output owns workspaces base+1 .. base+10 (SUPER+1 is base+1)
--   bar             eww window id of its bar
--   windows         other eww windows that live on this output
--   backlight       how levelctl sets its brightness: 'brightnessctl' or 'ddcutil'
return {
  {
    name           = 'eDP-1',
    internal       = true,
    mode           = '1920x1080',
    position       = '0x665',
    scale          = '1',
    workspace_base = 0,
    bar            = 'laptop_bar',
    windows        = { 'monitor', 'finance', 'quote' },
    backlight      = 'brightnessctl',
  },
  {
    name           = 'HDMI-A-1',
    mode           = '2560x1440@144.01Hz',
    position       = '1920x0',
    scale          = '1',
    workspace_base = 10,
    bar            = 'ew270q_bar',
    windows        = {},
    backlight      = 'ddcutil',
  },
}
