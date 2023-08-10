local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, {})
vim.keymap.set('n', '<leader>gf', builtin.git_files, {})
vim.keymap.set('n', '<leader>gr', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

-- vim.keymap.set('n', '<leader>v', ':vs<CR><Bar>:lua require("telescope.builtin").find_files()<CR><C-w>L', {})

require('telescope').setup({
  defaults = {
    layout_config = {
        prompt_position = 'top',
        preview_width = 0.55,
    },
    sorting_strategy = 'ascending'
  },
})
