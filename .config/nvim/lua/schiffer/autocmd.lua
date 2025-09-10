-- vim.api.nvim_create_autocmd('BufWritePre', {
--     desc = 'automatically compile tex',
--     pattern = { "*.tex" },
--     callback = function(_)
--         vim.cmd("!vim-tex.sh " .. vim.fn.expand("%<"))
--     end,
-- })

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'delete trailing whitespaces',
  callback = function(_)
    vim.cmd([[norm mq]])
    pcall(vim.cmd([[%s/\s\+$//e]]))
    vim.cmd([[norm 'q]])
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'format on save',
  callback = function(_)
    vim.lsp.buf.format()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "css", "scss", "html", "lua", "json", "yaml", "tsx" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})
