return {
  'williamboman/mason-lspconfig.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
  },

  config = function()
    vim.lsp.config('*', {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })

    require('mason').setup()
    require('mason-lspconfig').setup()

    -- Servers installed by Nix (nix/home/editor.nix), enabled when found on PATH.
    -- mason-lspconfig above only enables the ones Mason installed.
    for name, exe in pairs({
      lua_ls = 'lua-language-server',
      gopls = 'gopls',
      basedpyright = 'basedpyright-langserver',
      bashls = 'bash-language-server',
      cssls = 'vscode-css-language-server',
      html = 'vscode-html-language-server',
      jsonls = 'vscode-json-language-server',
      eslint = 'vscode-eslint-language-server',
      ts_ls = 'typescript-language-server',
      yamlls = 'yaml-language-server',
      terraformls = 'terraform-ls',
      tflint = 'tflint',
      texlab = 'texlab',
      dockerls = 'docker-langserver',
      docker_compose_language_service = 'docker-compose-langserver',
      tailwindcss = 'tailwindcss-language-server',
      emmet_language_server = 'emmet-language-server',
      nil_ls = 'nil',
    }) do
      if vim.fn.executable(exe) == 1 then
        vim.lsp.enable(name)
      end
    end

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

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
        },
      },
    })

    -- workflows and composite action manifests go to gh_actions_ls, other yaml to yamlls
    local function is_gh_actions(bufnr)
      local path = vim.api.nvim_buf_get_name(bufnr)
      local name = vim.fs.basename(path)
      return vim.fs.dirname(path):match('/%.github/workflows$') ~= nil or name == 'action.yml' or name == 'action.yaml'
    end

    vim.lsp.config('gh_actions_ls', {
      root_dir = function(bufnr, on_dir)
        if is_gh_actions(bufnr) then
          on_dir(vim.fs.root(bufnr, '.git') or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
        end
      end,
    })

    vim.lsp.config('yamlls', {
      root_dir = function(bufnr, on_dir)
        if not is_gh_actions(bufnr) then
          on_dir(vim.fs.root(bufnr, '.git') or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
        end
      end,
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
