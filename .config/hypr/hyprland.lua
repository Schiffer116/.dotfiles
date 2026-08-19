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

hl.monitor({
  output   = 'eDP-1',
  mode     = '1920x1080',
  position = '0x665',
  scale    = '1',
})

hl.monitor({
  output   = 'HDMI-A-1',
  mode     = '2560x1440@144.01Hz',
  position = '1920x0',
  scale    = '1',
  -- cm       = "hdr"
})

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
  hl.exec_cmd('hyprpaper')
  hl.exec_cmd('hyprsunset --temperature 1000')
  hl.exec_cmd('fcitx5 -d')
  hl.exec_cmd('mako')
  hl.exec_cmd('hypr_ipc.sh')
  hl.exec_cmd([[
    eww open-many bar:laptop_bar --arg laptop_bar:monitor_id=0 \
                  bar:ew270q_bar --arg ew270q_bar:monitor_id=1 \
                  monitor
  ]])
  hl.exec_cmd('eww set app_json="$(launcher.sh fuzzy)"')
  hl.exec_cmd('volume_controller')
  hl.exec_cmd('ollama serve')
  hl.exec_cmd('hyprctl setcursor Bibata-Modern-Ice 30')
  -- hl.exec_cmd('brave', { workspace = "1" })
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
hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('eww open --toggle search_menu'))
hl.bind(mainMod .. ' + SHIFT + Space', hl.dsp.window.float({ action = 'toggle' }))
hl.bind(mainMod .. ' + F', hl.dsp.window.fullscreen({ action = 'toggle' }))
hl.bind(mainMod .. ' + C', hl.dsp.exec_cmd('mpv /dev/video0 --profile=low-latency --untimed'))
hl.bind(mainMod .. ' + Return', hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. ' + CTRL + SHIFT + P', hl.dsp.window.pin())

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

local all_wallpapers = {
  "bonaparte_before_the_sphinx.jpg",
  "cityscape.png",
  "hand.png",
  "koi-fishes.png",
  "lucylucy.jpg",
  "minimal.png",
  "moon.png",
  "neko.png",
  "nord-street.png",
  "ronin.png",
  "science_ball.png",
  "snowhat.png",
  "the_death_of_julius_caesar.jpg",
  "the_fallen_angel.jpg",
  "twilight.png"
}

local function dispatch_relative_workspace(callback, option)
  local active_monitor = hl.get_active_monitor()
  if active_monitor == nil then
    return nil
  end

  local monitors = { "eDP-1", "HDMI-A-1" }
  for i, monitor in ipairs(monitors) do
    if active_monitor.name == monitor then
      option.workspace = (i - 1) * 10 + option.workspace
    end
  end
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

hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd('volume.sh increase'), { locked = true, repeating = true })
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd('volume.sh decrease'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('volume.sh set 1%+'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86AudioLowerVolume', hl.dsp.exec_cmd('volume.sh set 1%-'), { locked = true, repeating = true })
hl.bind('XF86AudioMute', hl.dsp.exec_cmd('volume.sh toggle-mute'), { locked = true })
hl.bind('XF86MonBrightnessUp', hl.dsp.exec_cmd('brightness.sh set +5%'), { locked = true, repeating = true })
hl.bind('XF86MonBrightnessDown', hl.dsp.exec_cmd('brightness.sh set 5%-'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86MonBrightnessUp', hl.dsp.exec_cmd('brightness.sh set +1%'), { locked = true, repeating = true })
hl.bind('SHIFT + XF86MonBrightnessDown', hl.dsp.exec_cmd('brightness.sh set 1%-'), { locked = true, repeating = true })
hl.bind('ALT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('brightness.sh set +5%'), { locked = true, repeating = true })
hl.bind('ALT + XF86AudioLowerVolume', hl.dsp.exec_cmd('brightness.sh set 5%-'), { locked = true, repeating = true })
hl.bind('ALT + SHIFT + XF86AudioRaiseVolume', hl.dsp.exec_cmd('brightness.sh set +1%'),
  { locked = true, repeating = true })
hl.bind('ALT + SHIFT + XF86AudioLowerVolume', hl.dsp.exec_cmd('brightness.sh set 1%-'),
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
hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('launcher.sh open'))
-- hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('hyprlauncher'))

hl.define_submap("powermenu", function()
  hl.bind('Tab', hl.dsp.exec_cmd('powermenu.sh next'))
  hl.bind('SHIFT + Tab', hl.dsp.exec_cmd('powermenu.sh previous'))
  hl.bind('Return', hl.dsp.exec_cmd('powermenu.sh action'))

  hl.bind(mainMod .. ' + X', hl.dsp.exec_cmd('powermenu.sh close'))
  hl.bind('Escape', hl.dsp.exec_cmd('powermenu.sh close'))
end)

hl.define_submap("launcher", function()
  hl.bind('Tab', hl.dsp.exec_cmd('launcher.sh next'))
  hl.bind('SHIFT + Tab', hl.dsp.exec_cmd('launcher.sh previous'))
  hl.bind('Return', hl.dsp.exec_cmd('launcher.sh launch'))

  hl.bind(mainMod .. ' + D', hl.dsp.exec_cmd('launcher.sh close'))
  hl.bind('Escape', hl.dsp.exec_cmd('launcher.sh close'))
end)

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

for i, m in ipairs({ "eDP-1", "HDMI-A-1" }) do
  for j = 1, 10 do
    hl.workspace_rule({
      workspace = tostring((i - 1) * 10 + j),
      monitor = m,
    })
  end
end

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
