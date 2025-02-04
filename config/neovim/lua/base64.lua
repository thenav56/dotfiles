local M = {}

-- Base64 Decode
function M.decode()
  local selection = vim.fn.getreg('"')  -- Get the selected text from the register
  local decoded = vim.fn.system('base64 -d', selection)  -- Run the decode command
  vim.fn.setreg('"', decoded)  -- Set the decoded text back into the register
  vim.cmd('normal! gvP')  -- Reselect the original area and paste the decoded result
end

-- Base64 Encode
function M.encode()
  local selection = vim.fn.getreg('"')  -- Get the selected text from the register
  local encoded = vim.fn.system('base64', selection)  -- Run the encode command
  vim.fn.setreg('"', encoded)  -- Set the encoded text back into the register
  vim.cmd('normal! gvP')  -- Reselect the original area and paste the encoded result
end

return M
