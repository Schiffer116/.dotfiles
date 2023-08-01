local lspconfig = require('lspconfig')
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()


require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
  }
})


vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local opts = {buffer = bufnr, remap = false}

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<rrader>vrr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
    end
})


local cmp = require('cmp')
local cmp_select_opts = {behavior = cmp.SelectBehavior.Select}

cmp.setup({
  sources = {
    {name = 'nvim_lsp'},
  },
  mapping = {
    ['<CR>'] = cmp.mapping.confirm({select = true}),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<Up>'] = cmp.mapping.select_prev_item(cmp_select_opts),
    ['<Down>'] = cmp.mapping.select_next_item(cmp_select_opts),
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
  },
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
    fields = {'abbr', 'menu', 'kind'},
    format = function(entry, item)
      local short_name = {
        nvim_lsp = 'LSP',
        nvim_lua = 'nvim'
      }

      local menu_name = short_name[entry.source.name] or entry.source.name

      item.menu = string.format('[%s]', menu_name)
      return item
    end,
  },
})


require('mason-lspconfig').setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      capabilities = lsp_capabilities,
    })
  end,
})
