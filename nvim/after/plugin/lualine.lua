require('lualine').setup({
    options = {
        icon_enabled = true,
    },
    sections = {
        lualine_a = {
            {
                'buffers',
            }
        }
    }
})

