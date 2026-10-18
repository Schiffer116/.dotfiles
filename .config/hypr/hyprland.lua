-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require('myColors')

local mainMod = 'SUPER' -- Sets 'Windows' key as main modifier

------------------
---- MONITORS ----
------------------

local monitors = require('monitors')

local monitor_by_name = {}
local internal_monitor
for _, m in ipairs(monitors) do
  monitor_by_name[m.name] = m
  if m.internal then
    internal_monitor = m
  end
end

local function add_workspace_rules(m)
  for j = 1, 10 do
    hl.workspace_rule({ workspace = tostring(m.workspace_base + j), monitor = m.name })
  end
end

local function json_string(s)
  return '"' .. (s:gsub('[%c"\\]', function(c) return string.format('\\u%04x', c:byte()) end)) .. '"'
end

-- Publish the table for eww-windows.sh and levelctl. Rewritten on every change, never stale.
local function write_monitors_json()
  local entries = {}
  for _, m in ipairs(monitors) do
    local windows = {}
    for _, w in ipairs(m.windows) do
      table.insert(windows, json_string(w))
    end
    table.insert(entries, string.format(
      '{"name":%s,"internal":%s,"workspace_base":%d,"bar":%s,"windows":[%s],"backlight":%s}',
      json_string(m.name), tostring(m.internal == true), m.workspace_base, json_string(m.bar),
      table.concat(windows, ','), m.backlight and json_string(m.backlight) or 'null'))
  end
  local path = os.getenv('XDG_RUNTIME_DIR') .. '/monitors.json'
  local f = io.open(path .. '.tmp', 'w')
  if f == nil then
    return
  end
  f:write('[' .. table.concat(entries, ',') .. ']\n')
  f:close()
  os.rename(path .. '.tmp', path)
end

-- An output missing from the table gets the next free workspace base and a bar.
local function adopt_unknown_monitors()
  local changed = false
  for _, mon in ipairs(hl.get_monitors()) do
    if monitor_by_name[mon.name] == nil then
      local base = 0
      for _, m in ipairs(monitors) do
        base = math.max(base, m.workspace_base + 10)
      end
      local m = { name = mon.name, workspace_base = base, bar = 'bar_' .. mon.name:gsub('%W', '_'), windows = {} }
      table.insert(monitors, m)
      monitor_by_name[m.name] = m
      add_workspace_rules(m)
      changed = true
    end
  end
  if changed then
    write_monitors_json()
  end
end

for _, m in ipairs(monitors) do
  if not m.internal then
    hl.monitor({ output = m.name, mode = m.mode, position = m.position, scale = m.scale })
  end
  add_workspace_rules(m)
end
write_monitors_json()

-- Lid: logind ignores the switch (system/logind.conf.d/lid.conf), so closing it never
-- suspends and the laptop keeps running as a headless server. Closing only turns the panel
-- off: with another output connected the panel is disabled so its workspaces move over,
-- otherwise it goes DPMS off (disabling the only monitor would leave Hyprland on a fallback output).
local function lid_is_closed()
  local f = io.open('/proc/acpi/button/lid/LID0/state')
  if f == nil then
    return false
  end
  local state = f:read('a')
  f:close()
  return state:find('closed') ~= nil
end

local function external_connected()
  for _, mon in ipairs(hl.get_monitors()) do
    if mon.name ~= internal_monitor.name then
      return true
    end
  end
  return false
end

local function set_internal_monitor(disabled)
  hl.monitor({
    output   = internal_monitor.name,
    mode     = internal_monitor.mode,
    position = internal_monitor.position,
    scale    = internal_monitor.scale,
    disabled = disabled,
  })
end

local function apply_lid()
  local closed = lid_is_closed()
  local disable = closed and external_connected()
  -- Only touch the layout when it changes, so the monitor events below cannot loop.
  if disable ~= (hl.get_monitor(internal_monitor.name) == nil) then
    set_internal_monitor(disable)
  end
  if not disable then
    hl.dispatch(hl.dsp.dpms({ action = closed and 'off' or 'on', monitor = internal_monitor.name }))
  end
end

-- Any output change: fix the lid layout, then match the eww windows to the outputs left.
local function on_monitors_changed()
  adopt_unknown_monitors()
  apply_lid()
  hl.exec_cmd('eww-windows.sh sync')
end

set_internal_monitor(lid_is_closed() and external_connected())

hl.bind('switch:on:Lid Switch', apply_lid, { locked = true })
hl.bind('switch:off:Lid Switch', apply_lid, { locked = true })
-- Plugging or unplugging an output (with the lid closed: moves the session to whichever is left).
hl.on('monitor.added', on_monitors_changed)
hl.on('monitor.removed', on_monitors_changed)

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = 'kitty'
local browser  = 'brave'

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on('hyprland.start', function()
  hl.exec_cmd('dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP')
  hl.exec_cmd('wl-paste -w notify_copy.sh')
  hl.exec_cmd('wl-paste --type text --watch cliphist store')
  hl.exec_cmd('wl-paste --type image --watch cliphist store')
  hl.exec_cmd('hyprpaper')
  hl.exec_cmd('hyprsunset --temperature 1000')
  hl.exec_cmd('fcitx5 -d')
  hl.exec_cmd('mako')
  adopt_unknown_monitors()
  hl.exec_cmd('eww-windows.sh sync')
  hl.exec_cmd('tmux-session.sh --cache')
  hl.exec_cmd('levelctl daemon')
  hl.exec_cmd('sleep-log.sh')
  hl.exec_cmd('hyprctl setcursor Bibata-Modern-Ice 30')
  hl.exec_cmd('wpctl set-mute @DEFAULT_SOURCE@ 1')
  hl.exec_cmd('brave', { workspace = "11" })
  hl.exec_cmd('kitty herdr', { workspace = "12" })
  hl.exec_cmd('kitty', { workspace = "special:terminal" })
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- env = AQ_DRM_DEVICES,/dev/dri/card1

hl.env('MOZ_ENABLE_WAYLAND', '1')
hl.env('ANKI_WAYLAND', '1')

-- env = GDK_BACKEND, wayland, x11, *

hl.env('QT_AUTO_SCREEN_SCALE_FACTOR', '1')
hl.env('QT_QPA_PLATFORM', 'wayland;xcb')

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env('XCURSOR_SIZE', '24')
hl.env('HYPRCURSOR_SIZE', '30')

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission('/usr/(bin|local/bin)/grim', 'screencopy', 'allow')
-- hl.permission('/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland', 'screencopy', 'allow')
-- hl.permission('/usr/(bin|local/bin)/hyprpm', 'plugin', 'allow')


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
  binds = {
    workspace_back_and_forth = true
  },

  general = {
    gaps_in = 10,
    gaps_out = 20,
    border_size = 1,

    col = {
      active_border = 'rgba(a4b9efff)',
      inactive_border = 'rgba(121118ff)'
    },

    snap = {
      enabled = true,
    },
  },
})

----------------
---- GROUPS ----
----------------

hl.config({
  group = {
    col = {
      border_active = 'rgba(a4b9efff)',
      border_inactive = 'rgba(121118ff)',
      border_locked_active = 'rgba(a4b9efff)',
      border_locked_inactive = 'rgba(121118ff)',
    },

    groupbar = {
      indicator_height = 5,
      col = {
        active = 'rgba(ff7a7bff)',
        inactive = 'rgba(121118ff)',
        locked_active = 'rgba(a4b9efff)',
        locked_inactive = 'rgba(121118ff)',
      },
      render_titles = false,
    }

  }
})

hl.bind(mainMod .. ' + G', hl.dsp.group.toggle())
hl.bind(mainMod .. ' + SHIFT + G', hl.dsp.group.lock())
hl.bind(mainMod .. ' + Tab', hl.dsp.group.next())
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. ' + ALT + ' .. key, hl.dsp.group.active({ index = key }))
end
hl.bind(mainMod .. ' + SHIFT + + Tab', hl.dsp.group.prev())


--------------------
---- DECORATION ----
--------------------

hl.config({
  decoration = {
    rounding = 0,

    blur = {
      enabled = true,
      size = 5,
      passes = 2,
    },

    motion_blur = {
      -- enabled = true,
    },

    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = 'rgb(a3dfff)',
      color_inactive = 'rgb(101010)'
    },

    dim_special = 0.2
  },
})

----------------------
----- ANIMATIONS -----
----------------------

hl.config({
  animations = {
    enabled = true,
  },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve('easeOutQuint', { type = 'bezier', points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve('easeInOutCubic', { type = 'bezier', points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve('linear', { type = 'bezier', points = { { 0, 0 }, { 1, 1 } } })
hl.curve('almostLinear', { type = 'bezier', points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve('quick', { type = 'bezier', points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve('overshot', { type = 'bezier', points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })

-- Default springs
hl.curve('easy', { type = 'spring', mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

-- hl.animation({ leaf = 'global', enabled = true, speed = 10, bezier = 'default' })
hl.animation({ leaf = 'border', enabled = true, speed = 2, bezier = 'default' })
hl.animation({ leaf = 'windows', enabled = true, speed = 5, bezier = 'overshot', style = 'popin' })
hl.animation({ leaf = 'fade', enabled = true, speed = 3, bezier = 'quick' })
hl.animation({ leaf = 'layers', enabled = true, speed = 3.81, bezier = 'easeOutQuint' })
hl.animation({ leaf = 'fadeLayersIn', enabled = true, speed = 1.79, bezier = 'almostLinear' })
hl.animation({ leaf = 'fadeLayersOut', enabled = true, speed = 1.39, bezier = 'almostLinear' })
hl.animation({ leaf = 'workspaces', enabled = true, speed = 5, bezier = 'overshot', style = 'slide' })
hl.animation({ leaf = 'specialWorkspace', enabled = true, speed = 5, bezier = 'overshot', style = 'slidevert' })
hl.animation({ leaf = 'zoomFactor', enabled = true, speed = 7, bezier = 'quick' })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- 'Smart gaps' / 'No gaps when only'
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = 'w[--[[ tv1 ]]]', gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = 'f[1]',   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = 'no-gaps-wtv1',
--     match = { float = false, workspace = 'w[tv1]' },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = 'no-gaps-f1',
--     match = { float = false, workspace = 'f[1]' },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
  dwindle = {
    preserve_split = true,
    special_scale_factor = 0.7,
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
  master = {
    new_status = 'master',
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
  scrolling = {
    fullscreen_on_one_column = true,
  },
})

----------------
----  MISC  ----
----------------

hl.config({
  misc = {
    force_default_wallpaper      = 0,
    disable_hyprland_logo        = true,
    disable_splash_rendering     = true,
    animate_mouse_windowdragging = true,
    animate_manual_resizes       = true,
    vrr                          = 1,
  },
})


---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout = 'us',
    kb_variant = '',
    kb_model = '',

    kb_options = 'caps:swapescape',

    kb_rules = '',

    follow_mouse = 1,
    float_switch_override_focus = 0,

    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      drag_lock = true,
      disable_while_typing = true
    },
    sensitivity = 0.5
  },
})

hl.gesture({
  fingers = 4,
  direction = 'horizontal',
  action = 'workspace'
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
  name        = 'epic-mouse-v1',
  sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------


-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. ' + SHIFT + Space', hl.dsp.window.float({ action = 'toggle' }))
hl.bind(mainMod .. ' + F', hl.dsp.window.fullscreen({ action = 'toggle' }))
hl.bind(mainMod .. ' + C', hl.dsp.exec_cmd('mpv /dev/video0 --profile=low-latency --untimed'))
hl.bind(mainMod .. ' + Return', hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. ' + CTRL + SHIFT + P', hl.dsp.window.pin())
-- hl.bind(mainMod .. ' + V', hl.dsp.exec_cmd('pkill -USR1 sotto')) -- toggle sotto speech-to-text

-- Push-to-talk: run nerd-dictation while F13 is held
-- local nerd_dictation_mic = 'alsa_input.pci-0000_00_1f.3.analog-stereo'
-- hl.bind('F12', hl.dsp.exec_cmd(
--   'notify-send begin; nerd-dictation begin --simulate-input-tool WTYPE --pulse-device-name ' .. nerd_dictation_mic))
-- hl.bind('F12', hl.dsp.exec_cmd('notify-send end; nerd-dictation end'), { release = true })

-- Push-to-talk: unmute mic while mouse thumb button (remapped to F13 via ratbagctl) is held
-- Note: with this system's XKB config, evdev KEY_F13 resolves to keysym XF86Tools, not F13
hl.bind('XF86Tools', hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_SOURCE@ 0'), { locked = true })
hl.bind('XF86Tools', hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_SOURCE@ 1'), { locked = true, release = true })

hl.bind(mainMod .. ' + B', hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. ' + W', hl.dsp.window.close())
hl.bind(mainMod .. ' + SHIFT + M',
  hl.dsp.exec_cmd('command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch "hl.dsp.exit()"'))
hl.bind(mainMod .. ' + O', hl.dsp.layout('togglesplit')) -- dwindle only

hl.bind('ALT + E', hl.dsp.exec_cmd('language.sh set E'))
hl.bind('ALT + N', hl.dsp.exec_cmd('language.sh set J'))
hl.bind('ALT + V', hl.dsp.exec_cmd('language.sh set V'))

hl.bind(mainMod .. ' + H', hl.dsp.focus({ direction = 'left' }))
hl.bind(mainMod .. ' + L', hl.dsp.focus({ direction = 'right' }))
hl.bind(mainMod .. ' + K', hl.dsp.focus({ direction = 'up' }))
hl.bind(mainMod .. ' + J', hl.dsp.focus({ direction = 'down' }))

hl.bind(mainMod .. ' + SHIFT + H', hl.dsp.window.move({ direction = 'left', group_aware = true }))
hl.bind(mainMod .. ' + SHIFT + L', hl.dsp.window.move({ direction = 'right', group_aware = true }))
hl.bind(mainMod .. ' + SHIFT + K', hl.dsp.window.move({ direction = 'up', group_aware = true }))
hl.bind(mainMod .. ' + SHIFT + J', hl.dsp.window.move({ direction = 'down', group_aware = true }))

-- for i = 1, 10 do
--   local key = i % 10
--   hl.bind(mainMod .. ' + ' .. key, hl.dsp.focus({ workspace = i }))
--   hl.bind(mainMod .. ' + SHIFT + ' .. key, hl.dsp.window.move({ workspace = i }))
--   hl.bind(mainMod .. ' + CTRL + ' .. key, hl.dsp.window.move({ workspace = i, follow = false }))
-- end

local function dispatch_relative_workspace(callback, option)
  local active_monitor = hl.get_active_monitor()
  if active_monitor == nil then
    return nil
  end

  local m = monitor_by_name[active_monitor.name]
  option.workspace = (m and m.workspace_base or 0) + option.workspace
  hl.dispatch(callback(option))
end

for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. ' + ' .. key, function()
    dispatch_relative_workspace(hl.dsp.focus, { workspace = key })
  end)
  hl.bind(mainMod .. ' + SHIFT + ' .. key, function()
    dispatch_relative_workspace(hl.dsp.window.move, { workspace = key })
  end)
  hl.bind(mainMod .. ' + CTRL + ' .. key, function()
    dispatch_relative_workspace(hl.dsp.window.move, { workspace = key, follow = false })
  end)
end

hl.bind(mainMod .. ' + comma', hl.dsp.focus({ workspace = '-1' }))
hl.bind(mainMod .. ' + SHIFT + comma', hl.dsp.window.move({ workspace = '-1' }))
hl.bind(mainMod .. ' + CTRL + comma', hl.dsp.window.move({ workspace = '-1', follow = false }))

hl.bind(mainMod .. ' + period', hl.dsp.focus({ workspace = '+1' }))
hl.bind(mainMod .. ' + SHIFT + period', hl.dsp.window.move({ workspace = '+1' }))
hl.bind(mainMod .. ' + CTRL + period', hl.dsp.window.move({ workspace = '+1', follow = false }))

hl.bind(mainMod .. ' + U', hl.dsp.workspace.toggle_special('terminal'))
hl.bind(mainMod .. ' + I', hl.dsp.workspace.toggle_special('browser'))
hl.bind(mainMod .. ' + SHIFT + U', hl.dsp.window.move({ workspace = 'special:terminal' }))
hl.bind(mainMod .. ' + SHIFT + I', hl.dsp.window.move({ workspace = 'special:browser' }))
hl.bind(mainMod .. ' + CTRL + U', hl.dsp.window.move({ workspace = 'special:terminal', follow = false }))
hl.bind(mainMod .. ' + CTRL + I', hl.dsp.window.move({ workspace = 'special:browser', follow = false }))

hl.bind(mainMod .. ' + mouse_down', hl.dsp.focus({ workspace = 'e+1' }))
hl.bind(mainMod .. ' + mouse_up', hl.dsp.focus({ workspace = 'e-1' }))

hl.bind(mainMod .. ' + mouse:272', hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. ' + SHIFT + mouse:272', hl.dsp.window.resize(), { mouse = true })

-- Plain keys step 5%, SHIFT steps 1%. ALT + volume keys drive the brightness of the focused monitor.
hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd('levelctl volume +5'), { locked = true, repeating = true })
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd('levelctl volume -5'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('levelctl volume +1'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86AudioLowerVolume', hl.dsp.exec_cmd('levelctl volume -1'), { locked = true, repeating = true })
hl.bind('XF86AudioMute', hl.dsp.exec_cmd('levelctl volume toggle-mute'), { locked = true })
hl.bind('XF86MonBrightnessUp', hl.dsp.exec_cmd('levelctl brightness +5'), { locked = true, repeating = true })
hl.bind('XF86MonBrightnessDown', hl.dsp.exec_cmd('levelctl brightness -5'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86MonBrightnessUp', hl.dsp.exec_cmd('levelctl brightness +1'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86MonBrightnessDown', hl.dsp.exec_cmd('levelctl brightness -1'),
  { locked = true, repeating = true })
hl.bind('ALT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('levelctl brightness +5'), { locked = true, repeating = true })
hl.bind('ALT + XF86AudioLowerVolume', hl.dsp.exec_cmd('levelctl brightness -5'), { locked = true, repeating = true })
hl.bind('ALT + SHIFT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('levelctl brightness +1'),
  { locked = true, repeating = true })
hl.bind('ALT + SHIFT + XF86AudioLowerVolume', hl.dsp.exec_cmd('levelctl brightness -1'),
  { locked = true, repeating = true })

hl.bind('XF86AudioNext', hl.dsp.exec_cmd('playerctl next'), { locked = true })
hl.bind('XF86AudioPause', hl.dsp.exec_cmd('playerctl play-pause'), { locked = true })
hl.bind('XF86AudioPlay', hl.dsp.exec_cmd('playerctl play-pause'), { locked = true })
hl.bind('XF86AudioPrev', hl.dsp.exec_cmd('playerctl previous'), { locked = true })

hl.bind(mainMod .. ' + S', hl.dsp.exec_cmd('screenshot.sh --now'))
hl.bind(mainMod .. ' + SHIFT + S', hl.dsp.exec_cmd('screenshot.sh --area'))
hl.bind(mainMod .. ' + CTRL + S', hl.dsp.exec_cmd('screenshot.sh --win'))

-------------
---- EWW ----
-------------

hl.bind(mainMod .. ' + X', hl.dsp.exec_cmd('powermenu.sh open'))
hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('picker.sh launcher'))
hl.bind(mainMod .. ' + V', hl.dsp.exec_cmd('picker.sh clipboard'))

hl.define_submap("powermenu", function()
  hl.bind('Tab', hl.dsp.exec_cmd('powermenu.sh next'))
  hl.bind('SHIFT + Tab', hl.dsp.exec_cmd('powermenu.sh previous'))
  hl.bind('Return', hl.dsp.exec_cmd('powermenu.sh action'))

  hl.bind(mainMod .. ' + X', hl.dsp.exec_cmd('powermenu.sh close'))
  hl.bind('Escape', hl.dsp.exec_cmd('powermenu.sh close'))
end)

-- One submap for both pickers; CTRL+P (pin) only does something in the clipboard.
hl.define_submap("picker", function()
  hl.bind('Tab', hl.dsp.exec_cmd('picker.sh next'))
  hl.bind('SHIFT + Tab', hl.dsp.exec_cmd('picker.sh previous'))
  hl.bind('Return', hl.dsp.exec_cmd('picker.sh select'))
  hl.bind('CTRL + P', hl.dsp.exec_cmd('picker.sh toggle-pin'))
  hl.bind('Right', hl.dsp.exec_cmd('picker.sh next-page'))
  hl.bind('Left', hl.dsp.exec_cmd('picker.sh previous-page'))

  hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('picker.sh close'))
  hl.bind(mainMod .. ' + V', hl.dsp.exec_cmd('picker.sh close'))
  hl.bind('Escape', hl.dsp.exec_cmd('picker.sh close'))
end)

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
  -- Ignore maximize requests from all apps. You'll probably like this.
  name           = 'suppress-maximize-events',
  match          = { class = '.*' },

  suppress_event = 'maximize',
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name     = 'fix-xwayland-drags',
  match    = {
    class      = '^$',
    title      = '^$',
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})

hl.window_rule({
  name = "Browser's File Selector Window Size",
  match = {
    class = "xdg-desktop-portal-gtk",
    float = true
  },
  size = { 'monitor_w * 0.5', 'monitor_h * 0.5' },
  center = true,
})

hl.layer_rule({
  name  = 'Blur Powermenu',
  match = { namespace = 'powermenu' },
  blur  = true,
})

-- Hyprland-run windowrule
hl.window_rule({
  name  = 'move-hyprland-run',
  match = { class = 'hyprland-run' },

  move  = '20 monitor_h-120',
  float = true,
})
