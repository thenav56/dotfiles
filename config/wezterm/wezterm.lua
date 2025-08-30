-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
local appearance = require 'appearance'
local mux = wezterm.mux

local remote_emoji = '📡 '
-- local remote_emoji = '💼 '
local local_emoji = '🏠 '

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
    -- Copy mode
    { key = 'Space', mods = 'CTRL|SHIFT', action = act.EmitEvent 'trigger-vim-with-scrollback' },
    -- Mux
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
        window:set_right_status(hostname .. remote_emoji)
    else
        window:set_right_status(hostname .. local_emoji)
    end
end)

-- does this work?
wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

config.audible_bell = "Disabled"

config.adjust_window_size_when_changing_font_size = false

if wezterm.target_triple == 'aarch64-apple-darwin' then
    config.font = wezterm.font {
        family = 'CaskaydiaCove Nerd Font',
    }
    config.line_height = 1.5
    config.font_size = 12

    -- config.font = wezterm.font {
    --     family = 'IosevkaTerm Nerd Font',
    -- }
    -- config.line_height = 1.1
    -- config.font_size = 13

    config.font = wezterm.font {
        family = 'JetBrainsMono Nerd Font',
    }
    config.line_height = 1.1
    -- config.freetype_load_target = "Normal"
    config.font_size = 13

else
    config.line_height = 1.2
    config.font_size = 10.5
    config.font = wezterm.font {
        family = 'CaskaydiaCove NF',
    }
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
config.use_fancy_tab_bar = false
-- Don't let any individual tab name take too much room
config.tab_max_width = 32

if appearance.is_dark() then
    config.color_scheme = 'Catppuccin Mocha'
    -- config.color_scheme = 'Gruvbox dark, medium (base16)'

    config.colors = {
      tab_bar = {
        -- The color of the strip that goes along the top of the window
        -- (does not apply when fancy tab bar is in use)
        background = '#0b0022',

        -- The active tab is the one that has focus in the window
        active_tab = {
          -- The color of the background area for the tab
          bg_color = '#2aa198',
          -- The color of the text for the tab
          fg_color = '#073642',
          -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
          -- label shown for this tab.
          -- The default is "Normal"
          intensity = 'Normal',
          -- Specify whether you want "None", "Single" or "Double" underline for
          -- label shown for this tab.
          -- The default is "None"
          underline = 'None',
          -- Specify whether you want the text to be italic (true) or not (false)
          -- for this tab.  The default is false.
          italic = false,
          -- Specify whether you want the text to be rendered with strikethrough (true)
          -- or not for this tab.  The default is false.
          strikethrough = false,
        },

        -- Inactive tabs are the tabs that do not have focus
        inactive_tab = {
          bg_color = '#1b1032',
          fg_color = '#808080',
          -- The same options that were listed under the `active_tab` section above
          -- can also be used for `inactive_tab`.
        },

        -- You can configure some alternate styling when the mouse pointer
        -- moves over inactive tabs
        inactive_tab_hover = {
          bg_color = '#3b3052',
          fg_color = '#909090',
          italic = true,
          -- The same options that were listed under the `active_tab` section above
          -- can also be used for `inactive_tab_hover`.
        },

        -- The new tab button that let you create new tabs
        new_tab = {
          bg_color = '#1b1032',
          fg_color = '#808080',
          -- The same options that were listed under the `active_tab` section above
          -- can also be used for `new_tab`.
        },

        -- You can configure some alternate styling when the mouse pointer
        -- moves over the new tab button
        new_tab_hover = {
          bg_color = '#3b3052',
          fg_color = '#909090',
          italic = true,
          -- The same options that were listed under the `active_tab` section above
          -- can also be used for `new_tab_hover`.
        },

      },
    }

else
    config.color_scheme = 'One Light (base16)'

    config.colors = {
      tab_bar = {
        background = '#fafafa', -- base00: very light background for tab bar

        active_tab = {
          bg_color = '#e5e5e6', -- base02: slightly darker to indicate active
          fg_color = '#383a42', -- base05: dark readable text
          intensity = 'Bold',
          underline = 'None',
          italic = false,
          strikethrough = false,
        },

        inactive_tab = {
          bg_color = '#f0f0f1', -- base01: light gray background
          fg_color = '#a0a1a7', -- softer gray for inactive tab text
          intensity = 'Normal',
          underline = 'None',
          italic = false,
          strikethrough = false,
        },

        inactive_tab_hover = {
          bg_color = '#d0d0d1', -- subtle hover background
          fg_color = '#383a42',
          italic = true,
        },

        new_tab = {
          bg_color = '#f0f0f1', -- same as inactive_tab
          fg_color = '#a0a1a7',
        },

        new_tab_hover = {
          bg_color = '#e5e5e6', -- matches active tab bg
          fg_color = '#383a42',
          italic = true,
        },
      },
    }
end

-- Switch to the last active tab when I close a tab
config.switch_to_last_active_tab_when_closing_tab = true

-- Scrollback
config.scrollback_lines = 4000
config.enable_scroll_bar = false

-- Format the tab title and apply colors based on domain
wezterm.on(
    'format-tab-title',
    function(tab, tabs, panes, config, hover, max_width)
        local pane = tab.active_pane

        local is_remote = pane.domain_name ~= "local"
        if not is_remote then
            -- Don't do anything for local tabs
            return
        end

        local title = remote_emoji .. tab.tab_index .. ": " .. pane.title

        -- Add light/dark
        if tab.is_active then
            if appearance.is_dark() then
                return {
                    { Background = { Color = "#Add198" } },
                    { Foreground = { Color = "#073642" } },
                    { Text = " " .. title .. " " },
                }
            else
                return {
                    { Background = { Color = "#A5e5e6" } },
                    { Foreground = { Color = "#073642" } },
                    { Text = " " .. title .. " " },
                }
            end
        else
            if appearance.is_dark() then
                return {
                    { Background = { Color = "#2b1F32" } },
                    { Foreground = { Color = "#808090" } },
                    { Text = " " .. title .. " " },
                }
            else
                return {
                    { Background = { Color = "#D0f0f1" } },
                    { Foreground = { Color = "#808080" } },
                    { Text = " " .. title .. " " },
                }
            end
        end
    end
)

wezterm.on('trigger-vim-with-scrollback', function(window, pane)
    -- TODO: create a common function for this?
    local domain = pane:get_domain_name()
    local is_remote = domain and domain ~= "local"

    -- Retrieve the text from the pane
    local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

    -- Get cursor position (in scrollback coordinate space)
    local cursor = pane:get_cursor_position()
    local cursor_line = cursor.y
    local cursor_col = cursor.x

    -- Create a temporary file to pass to vim
    local name = os.tmpname()
    local f = io.open(name, 'w+')

    if f ~= nil then
        f:write(text)
        f:flush()
        f:close()
    end

    local home_dir = os.getenv("HOME")
    if is_remote then
        -- TODO: THis is not working for remote
        home_dir = "/home/navin"
    end

    -- Open a new window running vim and tell it to open the file
    window:perform_action(
        act.SpawnCommandInNewTab {
            args = {
                'bash', '-c',
                string.format(
                    "cat %s | %s/.config/kitty/scrollback_pager.sh 0 %s %s; sleep 20s",
                    name,
                    home_dir,
                    cursor_line,
                    cursor_col
                ),
            },
        },
        pane
    )

    -- Wait "enough" time for vim to read the file before we remove it.
    -- The window creation and process spawn are asynchronous wrt. running
    -- this script and are not awaitable, so we just pick a number.
    --
    -- Note: We don't strictly need to remove this file, but it is nice
    -- to avoid cluttering up the temporary directory.
    wezterm.sleep_ms(1000)
    os.remove(name)
end)

-- Finally, return the configuration to wezterm:
return config
