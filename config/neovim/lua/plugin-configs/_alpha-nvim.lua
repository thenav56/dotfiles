local fortune = require'alpha.fortune'()
local startify = require'alpha.themes.startify'

if not table.unpack then
	table.unpack = unpack
end

startify.section.header.val = {
    [[                                  __]],
    [[     ___     ___    ___   __  __ /\_\    ___ ___]],
    [[    / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\]],
    [[   /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \]],
    [[   \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
    [[    \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    table.unpack(fortune),
}

require'alpha'.setup(require'alpha.themes.startify'.opts)
