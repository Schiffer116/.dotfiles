return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'kyazdani42/nvim-web-devicons' },

  config = function()
    require('lualine').setup {
      options = {
        icon_enabled = true,
      },
      sections = {
        lualine_a = {
          {
            'buffers',
            mode = 0,
            use_mode_colors = true,
            -- buffers_color = {
            --   active = { bg = '#404060', gui = 'italic,bold' },
            --   inactive = { bg = '#202030' },
            -- },
          },
        },
        lualine_c = {}
      }
    }

    for i = 1, 9 do
      vim.keymap.set({ "n", "i", "v", "t" }, string.format("<A-%i>", i), function()
        xpcall(
          function() vim.cmd("LualineBuffersJump " .. i) end,
          function(_) vim.cmd([[LualineBuffersJump $]]) end
        )
      end)
    end
  end
}
