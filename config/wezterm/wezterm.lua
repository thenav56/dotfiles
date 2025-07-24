-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
local appearance = require 'appearance'
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

config.ssh_domains = {
    {
        name = 'wezterm-remote',
        remote_address = 'wezterm-remote',
    },
}

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
    {
        key = 'U',
        mods = 'CTRL|SHIFT',
        action = act.AttachDomain 'wezterm-remote',
    },
    {
        -- Open new tab next to current tab
        key = 't',
        mods = 'CMD',
        -- https://github.com/wez/wezterm/issues/909
        action = wezterm.action_callback(function(win, pane)
            local mux_win = win:mux_window()
            for _, item in ipairs(mux_win:tabs_with_info()) do
                if item.is_active then
                    mux_win:spawn_tab({})
                    win:perform_action(wezterm.action.MoveTab(item.index+1), pane)
                    return
                end
            end
        end),
    },
    -- Tab -------
    -- Move
    { key = ',', mods = 'CTRL|SHIFT', action = act.MoveTabRelative(-1) },
    { key = '.', mods = 'CTRL|SHIFT', action = act.MoveTabRelative(1) },
    -- Pane ------
    -- Zoom
    { key = 'z', mods = 'LEADER', action = wezterm.action.TogglePaneZoomState },
    -- New
    {
        key = 'Return',
        mods = 'LEADER|SHIFT',
        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'Return',
        mods = 'LEADER',
        action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    -- Close
    {
        key = 'w',
        mods = 'LEADER',
        action = act.CloseCurrentPane { confirm = false },
    },
    -- Navigation
    {
        key = 'h',
        mods = 'LEADER',
        action = act.ActivatePaneDirection 'Left',
    },
    {
        key = 'l',
        mods = 'LEADER',
        action = act.ActivatePaneDirection 'Right',
    },
    {
        key = 'k',
        mods = 'LEADER',
        action = act.ActivatePaneDirection 'Up',
    },
    {
        key = 'j',
        mods = 'LEADER',
        action = act.ActivatePaneDirection 'Down',
    },
    -- Move pane
    {
        key = 'Space',
        mods = 'LEADER|SHIFT',
        action = act.RotatePanes 'CounterClockwise',
    },
    { key = 'Space', mods = 'LEADER', action = act.RotatePanes 'Clockwise' },
    {  -- Swap with
        key = 's',
        mods = 'LEADER',
        action = act.PaneSelect {
            mode = 'SwapWithActiveKeepFocus',
        },
    },
}

wezterm.on("update-right-status", function(window, pane)
    local domain = pane:get_domain_name()
    local is_remote = domain and domain ~= "local"
    local hostname = is_remote and domain or wezterm.hostname()

    if is_remote then
        window:set_right_status(hostname .. " 💼 ")
    else
        window:set_right_status(hostname .. " 🏠 ")
    end
end)

-- does this work?
wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

-- Use it!
if appearance.is_dark() then
  config.color_scheme = 'catppuccin-mocha'
else
  config.color_scheme = 'One Light (base16)'
end

config.audible_bell = "Disabled"

config.line_height = 1.4
config.font_size = 10.5
config.font = wezterm.font {
    family = 'CaskaydiaCove NF',
}

if wezterm.target_triple == 'aarch64-apple-darwin' then
    config.font_size = 14.5
    config.font.family = 'Cascadia Code'
end

config.quit_when_all_windows_are_closed = false

config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
-- config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
  left = 5,
  right = 5,
  top = 1,
  bottom = 1,
}

config.window_background_opacity = 1
-- config.macos_window_background_blur = 40
config.window_frame = {
  font_size = 12.5,
}

-- Make it look like tabs, with better GUI controls
config.use_fancy_tab_bar = true
-- Don't let any individual tab name take too much room
config.tab_max_width = 32
config.colors = {
  tab_bar = {
    active_tab = {
      fg_color = '#073642',
      bg_color = '#2aa198',
    }
  }
}
-- Switch to the last active tab when I close a tab
config.switch_to_last_active_tab_when_closing_tab = true

-- Finally, return the configuration to wezterm:
return config
