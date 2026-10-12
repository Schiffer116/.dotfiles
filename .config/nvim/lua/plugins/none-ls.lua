return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    local null_ls = require("null-ls")

    -- skip formatters that are not installed instead of failing on every save
    local function has_exe(name)
      return function()
        return vim.fn.executable(name) == 1
      end
    end

    local sources = {
      -- JS/TS
      null_ls.builtins.formatting.prettier,
      -- Python
      null_ls.builtins.formatting.black.with({ condition = has_exe("black") }),
      -- Lua
      null_ls.builtins.formatting.stylua.with({ condition = has_exe("stylua") }),
      -- GitHub Actions
      null_ls.builtins.diagnostics.actionlint,
    }

    null_ls.setup({
      sources = sources,
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end
      end,
    })
  end
}
