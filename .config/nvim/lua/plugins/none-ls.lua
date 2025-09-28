return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    local null_ls = require("null-ls")

    local sources = {
      -- JS/TS
      null_ls.builtins.formatting.prettier,
      -- Python
      null_ls.builtins.formatting.black,
      -- Lua
      null_ls.builtins.formatting.stylua,
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
