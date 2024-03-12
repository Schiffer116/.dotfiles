return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2',
    dependencies = { 'nvim-lua/plenary.nvim' },

    config = function ()
        local builtin = require('telescope.builtin')

        vim.keymap.set('n', '<leader>f', builtin.find_files, {})
        vim.keymap.set('n', '<leader>gf', builtin.git_files, {})
        vim.keymap.set('n', '<leader>gr', builtin.live_grep, {})
        vim.keymap.set('n', '<leader>gh', builtin.help_tags, {})

        require('telescope').setup({
            defaults = {
                layout_config = {
                    prompt_position = 'top',
                    preview_width = 0.5,
                },
                sorting_strategy = 'ascending'
            },
            pickers = {
                find_files = {
                    hidden = true
                }
            },
        })
    end
}
