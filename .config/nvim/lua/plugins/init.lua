return {
    'xiyaowong/transparent.nvim',
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,

        config = function ()
            vim.cmd.colorscheme "catppuccin"
        end
    },
    {
        'numToStr/Comment.nvim',
        opts = { },
        lazy = false,
    },
}
