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
config.keys = {
  {
    key = 'U',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.AttachDomain 'wezterm-remote',
  },
  {
    key = 'W',
    mods = 'CTRL|SHIFT',
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Enter name for new workspace' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            act.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },
}

wezterm.on("update-right-status", function(window, pane)
  local domain = pane:get_domain_name()
  local is_remote = domain and domain ~= "local"
  local hostname = is_remote and domain or wezterm.hostname()

  window:set_right_status("󰒋 " .. hostname)
end)

-- does this work?
wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

-- Use it!
if appearance.is_dark() then
  config.color_scheme = 'Tokyo Night'
else
  config.color_scheme = 'Tokyo Night Day'
end


config.line_height = 1.4
config.font_size = 14.5
config.font = wezterm.font {
    family = 'Cascadia Code',
}

config.quit_when_all_windows_are_closed = false

config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
  left = 5,
  right = 5,
  top = 1,
  bottom = 1,
}

config.window_background_opacity = 0.9
config.macos_window_background_blur = 40
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
      -- I use a solarized dark theme; this gives a teal background to the active tab
      fg_color = '#073642',
      bg_color = '#2aa198',
    }
  }
}
-- Switch to the last active tab when I close a tab
config.switch_to_last_active_tab_when_closing_tab = true

-- Finally, return the configuration to wezterm:
return config
