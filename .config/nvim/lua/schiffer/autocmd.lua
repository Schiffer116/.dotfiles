vim.api.nvim_create_autocmd('BufWritePost', {
    desc = 'automatically compile tex',
    pattern = { "*.tex" },
    callback = function(_)
        vim.cmd("!vim-tex.sh " .. vim.fn.expand("%<"))
    end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
    desc = 'delete trailing whitespaces',
    callback = function(_)
        pcall(vim.cmd([[%s/\s\+$//e]]))
    end,
})
