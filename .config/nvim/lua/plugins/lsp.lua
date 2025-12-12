return {
  'williamboman/mason-lspconfig.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
  },

  config = function()
    require('mason').setup()
    require('mason-lspconfig').setup()

    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'LSP actions',
      callback = function(event)
        local opts = { buffer = bufnr, remap = false }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>rr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>t', vim.lsp.buf.type_definition, opts)
      end
    })

    -- local vim.lsp.config = require('lspconfig')

    local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
    require('mason-lspconfig').setup { handlers = {
      function(server_name)
        vim.lsp.config[server_name].setup({
          capabilities = lsp_capabilities,
        })
      end,
    } }

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
        },
      },
    })

    vim.lsp.config('texlab', {
      settings = {
        texlab = {
          build = {
            executable = 'texi2pdf',
            args = { '%f' },
            onSave = true,
          },
          chktex = {
            onOpenAndSave = true,
            onEdit = true,
          },
        },
      },
    }
    )

    vim.lsp.config('clangd', {
      root_dir = function(fname)
        return require("lspconfig.util").root_pattern(
          "Makefile",
          "configure.ac",
          "configure.in",
          "config.h.in",
          "build.ninja",
          "compile_commands.json",
          "compile_flags.txt",
          "CMakeLists.txt"
        )(fname) or require("lspconfig.util").find_git_ancestor(fname)
      end,
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
        "--header-insertion=iwyu",
        -- "--query-driver=/usr/lib/llvm-13/bin/clang++-15",
        "--all-scopes-completion",
        "--completion-style=detailed",
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    }
    )
  end
}
