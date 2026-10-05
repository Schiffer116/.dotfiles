return {
  -- only because catppuccin transparent background sucks
  {
    'xiyaowong/transparent.nvim',
    opts = {
      -- catppuccin sets these directly instead of linking to NormalFloat
      extra_groups = { "TroubleNormal", "TroubleNormalNC" },
    },
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    config = function()
      require("catppuccin").setup({
        auto_integrations = true,
        -- transparent_background = true,
        float = { transparent = true },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false
        },
        custom_highlights = function(colors)
          return {
            LineNr = { fg = colors.text },
            CursorLineNr = { fg = colors.text, bold = true },
          }
        end,
      })
      vim.cmd.colorscheme 'catppuccin'
    end
  },
}
