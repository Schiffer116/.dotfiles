return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  init = function()
    -- Disable entire built-in ftplugin mappings to avoid conflicts.
    -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
    vim.g.no_plugin_maps = true

    -- Or, disable per filetype (add as you like)
    -- vim.g.no_python_maps = true
    -- vim.g.no_ruby_maps = true
    -- vim.g.no_rust_maps = true
    -- vim.g.no_go_maps = true
  end,

  config = function()
    require("nvim-treesitter-textobjects").setup {
      select = {
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,
        -- You can choose the select mode (default is charwise 'v')
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * method: eg 'v' or 'o'
        -- and should return the mode ('v', 'V', or '<c-v>') or a table
        -- mapping query_strings to modes.
        selection_modes = {
          ['@function.inner'] = 'V',
          ['@function.outer'] = 'V',
          ['@class.inner'] = 'V',
          ['@class.outer'] = 'V',
          ['@conditional.inner'] = 'V',
          ['@conditional.outer'] = 'V',
          ['@loop.inner'] = 'V',
          ['@loop.outer'] = 'V',
        },
        -- If you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding or succeeding whitespace. Succeeding
        -- whitespace has priority in order to act similarly to eg the built-in
        -- `ap`.
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * selection_mode: eg 'v'
        -- and should return true of false
        include_surrounding_whitespace = false,
      },
    }


    keymaps = {
      ['ir'] = '@parameter.inner',
      ['ar'] = '@parameter.outer',
      ['if'] = '@function.inner',
      ['af'] = '@function.outer',
      ['io'] = '@class.inner',
      ['ao'] = '@class.outer',
      ['ii'] = '@conditional.inner',
      ['ai'] = '@conditional.outer',
      ['il'] = '@loop.inner',
      ['al'] = '@loop.outer',
      ['ic'] = '@call.inner',
      ['ac'] = '@call.outer',
      ['ia'] = '@assignment.inner',
      ['aa'] = '@assignment.outer',
      ['la'] = '@assignment.lhs',
      ['ra'] = '@assignment.rhs',
    }
    -- keymaps
    -- You can use the capture groups defined in `textobjects.scm`
    for keymap, textobject in pairs(keymaps) do
      vim.keymap.set({ "x", "o" }, keymap, function()
        require "nvim-treesitter-textobjects.select".select_textobject(textobject, "textobjects")
      end)
    end

    -- keymaps
    vim.keymap.set("n", "<leader>sn", function()
      require("nvim-treesitter-textobjects.swap").swap_next "@parameter.inner"
    end)
    vim.keymap.set("n", "<leader>sp", function()
      require("nvim-treesitter-textobjects.swap").swap_previous "@parameter.outer"
    end)

    -- vim.keymap.set({ "x", "o" }, "am", function()
    --   require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects")
    -- end)
    -- vim.keymap.set({ "x", "o" }, "im", function()
    --   require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects")
    -- end)
    -- vim.keymap.set({ "x", "o" }, "ac", function()
    --   require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects")
    -- end)
    -- vim.keymap.set({ "x", "o" }, "ic", function()
    --   require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects")
    -- end)
    -- -- You can also use captures from other query groups like `locals.scm`
    -- vim.keymap.set({ "x", "o" }, "as", function()
    --   require "nvim-treesitter-textobjects.select".select_textobject("@local.scope", "locals")
    -- end)
    -- require 'nvim-treesitter.configs'.setup {
    --   ensure_installed = { "vim", "vimdoc" },
    --   sync_install = false,
    --   auto_install = true,
    --   highlight = {
    --     enable = true,
    --
    --     -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    --     -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    --     -- Using this option may slow down your editor, and you may see some duplicate highlights.
    --     -- Instead of true it can also be a list of languages
    --     additional_vim_regex_highlighting = false,
    --   },
    --   indent = {
    --     enable = true
    --   },
    --   textobjects = {
    --     select = {
    --       enable = true,
    --       lookahead = true,
    --       keymaps = {
    --         ['ir'] = '@parameter.inner',
    --         ['ar'] = '@parameter.outer',
    --         ['if'] = '@function.inner',
    --         ['af'] = '@function.outer',
    --         ['io'] = '@class.inner',
    --         ['ao'] = '@class.outer',
    --         ['ii'] = '@conditional.inner',
    --         ['ai'] = '@conditional.outer',
    --         ['il'] = '@loop.inner',
    --         ['al'] = '@loop.outer',
    --         ['ic'] = '@call.inner',
    --         ['ac'] = '@call.outer',
    --         ['ia'] = '@assignment.inner',
    --         ['aa'] = '@assignment.outer',
    --         ['la'] = '@assignment.lhs',
    --         ['ra'] = '@assignment.rhs',
    --       },
    --       -- You can choose the select mode (default is charwise 'v')
    --       --
    --       -- Can also be a function which gets passed a table with the keys
    --       -- * query_string: eg '@function.inner'
    --       -- * method: eg 'v' or 'o'
    --       -- and should return the mode ('v', 'V', or '<c-v>') or a table
    --       -- mapping query_strings to modes.
    --       selection_modes = {
    --         ['@function.inner'] = 'V',
    --         ['@function.outer'] = 'V',
    --         ['@class.inner'] = 'V',
    --         ['@class.outer'] = 'V',
    --         ['@conditional.inner'] = 'V',
    --         ['@conditional.outer'] = 'V',
    --         ['@loop.inner'] = 'V',
    --         ['@loop.outer'] = 'V',
    --       },
    --       -- If you set this to `true` (default is `false`) then any textobject is
    --       -- extended to include preceding or succeeding whitespace. Succeeding
    --       -- whitespace has priority in order to act similarly to eg the built-in
    --       -- `ap`.
    --       --
    --       -- Can also be a function which gets passed a table with the keys
    --       -- * query_string: eg '@function.inner'
    --       -- * selection_mode: eg 'v'
    --       -- and should return true of false
    --       include_surrounding_whitespace = false,
    --     },
    --   },
    -- }
  end
}
