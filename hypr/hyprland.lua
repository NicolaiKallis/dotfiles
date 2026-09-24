-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/
--
-- Migrated from hyprland.conf (hyprlang) to the Lua config format.
-- hyprlang is deprecated as of Hyprland 0.55 and is dropped in an upcoming
-- release; see https://hypr.land/news/26_lua/
--
-- You can split this configuration into multiple files.
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Layout left-to-right: 1440p dock monitor | 1080p USB-C monitor | laptop panel
hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "4480x0", scale = 1 })

-- Both LG monitors on the dock share one DisplayPort-MST link; its bandwidth
-- plus a GPU limit (Intel UHD 620) does not allow both to run 2560x1440 while
-- eDP-1 is active -- the kernel rejects it with ENOSPC, so the second monitor
-- must drop to 1080p in that setup.
-- CAUTION: the laptop's HDMI port (HDMI-A-2) and the Thunderbolt dock's video
-- feed (DP-2, MST parent of DP-5..9) share the same GPU output block (DDI,
-- encoder 134) -- they are mutually exclusive. While the dock drives any
-- display, HDMI is physically cut off and even reports "disconnected"/no EDID.
-- The other USB-C port is DP-1 (encoder 118, DDI B), independent of the dock --
-- dock 1440p60 + USB-C monitor + eDP all run simultaneously. BUT a USB-C->HDMI
-- (HDMI 1.4-class) adapter cable maxes out at 1080p: its converter chip rejects
-- every 2560x1440 timing (kernel EINVAL on atomic test, any refresh/clock)
-- while CEA modes incl. 1080p120 pass. Use a USB-C->DisplayPort cable into the
-- monitor's DP input for 1440p60. Dock HDMI won't help either way (rides the
-- same MST link).
-- Matched by desc because MST connector names can change between boots/replugs.
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 312NTRL3G222",
    mode     = "2560x1440@59.95",
    position = "0x0",
    scale    = 1,
})

-- 1080p60 on purpose (2026-07-28): on the new USB-C->DP cable the link trained
-- at ~1/4 bandwidth (only pixel clocks <=148.5 MHz commit; 1440p AND 1080p120
-- now EINVAL -- different failure pattern than the old HDMI adapter, which
-- passed 1080p120/297 MHz). Any mode the link can't carry makes Hyprland walk
-- failing test-modesets, and Hyprland 0.56.0/aquamarine 0.13.0 can segfault in
-- releaseStashedCommit() right after such a walk on hotplug (6 identical crash
-- reports, 2026-07-27) -- so this rule must stay at a mode that commits cleanly.
-- After reseating/flipping the USB-C plug retrains the link at full rate,
-- switch to 2560x1440@59.95.
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 311NTNH4M831",
    mode     = "1920x1080@60",
    position = "2560x0",
    scale    = 1,
})

-- Fallback for any other output
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "wofi --show drun"
local browser     = "firefox"

-- window rules
-- hl.window_rule({ match = { class = "firefox" }, workspace = "special:ai silent" })


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- `hyprland.start` fires once per Hyprland startup, matching the old exec-once.
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("dunst & waybar & hyprpaper")

    -- Terminal
    hl.exec_cmd(terminal, { workspace = "1 silent" })

    -- Firefox working space
    hl.exec_cmd(browser, { workspace = "2 silent" })

    -- GPT / AI assistance screen
    -- hl.exec_cmd(browser .. " --new-window https://chatgpt.com", { workspace = "3 silent" })

    -- Docs window
    hl.exec_cmd("obsidian", { workspace = "4 silent" })

    -- Email client
    hl.exec_cmd("thunderbird", { workspace = "5 silent" })
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 2,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 5,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.6,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper    = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo      = true, -- If true disables the random hyprland logo / anime girl background. :(
        initial_workspace_tracking = 0,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "de",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:none",
        kb_rules   = "",

        follow_mouse = 0,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },

    gestures = {
        workspace_swipe_touch = false,
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle: toggle side/top split

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- NOTE: Artifacts from standard hyprland conf
-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
-- Region screenshot -> file + clipboard.
-- The filename is captured once into $f; calling $(date) twice (as the old
-- hyprland.conf did) could straddle a second tick, leaving wl-copy reading a
-- path grim never wrote.
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(
    [[f="$HOME/Pictures/screen_$(date +%F_%T).png" && grim -g "$(slurp)" "$f" && wl-copy < "$f"]]
))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- open rofi
hl.bind("SUPER + space", hl.dsp.exec_cmd("bash /home/nak/.config/hypr/drun-here.sh"))

-- lock screen using hyprlock
hl.bind("SUPER + X", hl.dsp.exec_cmd("hyprlock"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                        { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Ignore maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        xwayland = true,
        float    = true,
    },

    no_focus = true,
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
