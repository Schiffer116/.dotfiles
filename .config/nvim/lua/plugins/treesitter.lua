return {
    -- "nvim-treesitter/nvim-treesitter-context",
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
    },

    config = function ()
        vim.filetype.add({
            pattern = { [".*/hyprland%.conf"] = "hyprlang" },
        })
        require'nvim-treesitter.configs'.setup {
            ensure_installed = { "vim", "vimdoc" },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,

                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = false,
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
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
                        -- ['aa'] = '@assignment.inner',
                        -- ['ia'] = '@assignment.outer',
                        ['la'] = '@assignment.lhs',
                        ['ra'] = '@assignment.rhs',
                    },
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
            },
        }
    end
}
