return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lua',
    {
      "L3MON4D3/LuaSnip",
      build = "make install_jsregexp"
    },
    "onsails/lspkind.nvim"
  },

  config = function()
    local cmp = require('cmp')
    local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }
    local lspkind = require('lspkind')

    cmp.setup({
      sources = cmp.config.sources({
        { name = 'supermaven' },
        { name = 'path' },
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'nvim_lua' },
        { name = "codeium" },
        { name = 'vim-dadbod-completion' },
      }),
      mapping = cmp.mapping.preset.insert({
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-p>'] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_prev_item(cmp_select_opts)
          else
            cmp.complete()
          end
        end),
        ['<C-n>'] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item(cmp_select_opts)
          else
            cmp.complete()
          end
        end),
      }),
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },

      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },

      formatting = {
        format = lspkind.cmp_format({
          symbol_map = { Supermaven = "" },
          mode = 'symbol_text',
          maxwidth = {
            menu = 50, -- leading text (labelDetails)
            abbr = 50, -- actual suggestion item
          },
          ellipsis_char = '...',
          show_labelDetails = true,

          before = function(entry, vim_item)
            -- vim.o.pumheight = 20
            -- vim.o.pumwidth = 50

            vim_item.kind = string.format('%s %s', lspkind.symbol_map[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
                nvim_lsp = "[LSP]",
                path = "[Path]",
                buffer = "[Buffer]",
                nvim_lua = "[Lua]",
                luasnip = "[LuaSnip]",
                latex_symbols = "[LaTeX]",
                supermaven = "[Supermaven]",
              })[entry.source.name]

            return vim_item
          end
        })
      },


      experimental = { ghost_text = false },
    })

    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' }
      }
    })

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      })
    })
  end
}
