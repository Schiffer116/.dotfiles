return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",

    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      local parsers = {
        "bash",
        "c",
        "cpp",
        "css",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "yuck",
      }

      require("nvim-treesitter").install(parsers)

      -- Neovim's bundled ftplugins (lua, c, markdown, ...) call
      -- vim.treesitter.start() themselves; languages without one (like yuck)
      -- need highlighting started manually on the main branch.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "yuck" },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
