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
