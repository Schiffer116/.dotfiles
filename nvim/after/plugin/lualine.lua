require('lualine').setup({
    options = {
        icon_enabled = true,
        theme = 'catppuccin',
    },
    sections = {
        lualine_a = {
            {
                'buffers',
            }
        }
    }
})

