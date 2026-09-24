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

local shiftwidth_by_filetype = {
  javascript = 2,
  javascriptreact = 2,
  typescript = 2,
  typescriptreact = 2,
  css = 2,
  scss = 2,
  html = 2,
  lua = 2,
  json = 2,
  yaml = 2,
  tsx = 2,
  jsx = 2,
  python = 4,
  go = 4,
}

vim.api.nvim_create_autocmd("FileType", {
  desc = "set shiftwidth/tabstop based on filetype",
  pattern = vim.tbl_keys(shiftwidth_by_filetype),
  callback = function(args)
    local width = shiftwidth_by_filetype[args.match]
    if width then
      vim.opt_local.shiftwidth = width
      vim.opt_local.tabstop = width
      vim.opt_local.softtabstop = width
    end
  end,
})
