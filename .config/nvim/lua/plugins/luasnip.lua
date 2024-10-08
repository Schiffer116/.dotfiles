return {
    "L3MON4D3/LuaSnip",
    dependencies = { 'nvim-cmp' },
    config = function()
        local ls = require 'luasnip'

        vim.keymap.set({ "i", "s" }, "<C-k>", function()
            if ls.expand_or_jumpable() then
                ls.expand_or_jump()
            end
        end, {silent = true})
        vim.keymap.set({ "i", "s" }, "<C-j>", function()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end, {silent = true})
        vim.keymap.set({ "i", "s" }, "<C-l>", function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, {silent = true})

        ls.config.set_config {
            history = true,
            updateevents = "TextChanged,TextChangedI",
            enable_autosnippets = true,
        }
        ls.add_snippets('lua', {
            ls.parser.parse_snippet('lf', 'local $1 = function($2)\n  $0\nend')
        })
    end,
}
