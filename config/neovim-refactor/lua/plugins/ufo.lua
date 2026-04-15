vim.pack.add({
  "https://github.com/kevinhwang91/promise-async",
  "https://github.com/kevinhwang91/nvim-ufo",
})

local ufo = require("ufo")

local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)  -- Create suffix with fold size
  local sufWidth = vim.fn.strdisplaywidth(suffix)  -- Get the width of the suffix
  local targetWidth = width - sufWidth  -- Calculate space left for the text
  local curWidth = 0  -- Initialize the current width of the text being processed

  for _, chunk in ipairs(virtText) do  -- Iterate over each chunk of virtual text
    local chunkText = chunk[1]  -- Get the text part of the chunk
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)  -- Get the width of the chunk

    -- If there's enough space for the chunk, add it
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      -- Truncate the text to fit in the remaining space
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]  -- Get the highlight group of the chunk
      table.insert(newVirtText, {chunkText, hlGroup})  -- Add truncated chunk to newVirtText

      -- Update chunk width after truncation
      chunkWidth = vim.fn.strdisplaywidth(chunkText)

      -- If there's still space left, pad with spaces
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break  -- Stop after processing the chunk that didn't fit
    end

    curWidth = curWidth + chunkWidth  -- Update the current width
  end

  -- Add the suffix with "MoreMsg" highlight group at the end
  table.insert(newVirtText, {suffix, "MoreMsg"})

  return newVirtText
end


ufo.setup({
    open_fold_hl_timeout = 150,
    close_fold_kinds_for_ft = {
        default = {"imports", "comment"},
        json = {"array"},
        c = {"comment", "region"}
    },
    fold_virt_text_handler = handler,  -- Set custom fold virtual text handler
    provider_selector = function(bufnr, filetype, buftype)
        return {"treesitter", "indent"}
    end
})


vim.opt.foldenable = true
-- vim.opt.foldcolumn = "auto:9"
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.opt.foldlevelstart = 99
vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.keymap.set("n", "zR", ufo.openAllFolds)
vim.keymap.set("n", "zM", ufo.closeAllFolds)
vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds)
vim.keymap.set("n", "zm", ufo.closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)

-- Space to toggle fold
vim.api.nvim_set_keymap("n", "<Space>", "za", { noremap = true, silent = true })

-- Set highlight groups using lua
vim.api.nvim_set_hl(0, "UfoFoldedFg", { fg = vim.api.nvim_get_hl_by_name("Normal", true).foreground })
vim.api.nvim_set_hl(0, "UfoFoldedBg", { bg = vim.api.nvim_get_hl_by_name("Folded", true).background })

-- Link highlight groups
vim.api.nvim_command("highlight! link UfoPreviewSbar PmenuSbar")
vim.api.nvim_command("highlight! link UfoPreviewThumb PmenuThumb")
vim.api.nvim_command("highlight! link UfoPreviewWinBar UfoFoldedBg")
vim.api.nvim_command("highlight! link UfoPreviewCursorLine Visual")
vim.api.nvim_command("highlight! link UfoFoldedEllipsis Comment")
vim.api.nvim_command("highlight! link UfoCursorFoldedLine CursorLine")
