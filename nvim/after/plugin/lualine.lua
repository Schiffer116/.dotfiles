require('lualine').setup({
    options = {
        icon_enabled = true,
    },
    sections = {
        lualine_a = {
            {
                'buffers',
                 mode = 2,
            }
        }
    }
})
vim.keymap.set({"n", "i", "v"}, "<C-b>1", "<cmd>LualineBuffersJump 1<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>2", "<cmd>LualineBuffersJump 2<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>3", "<cmd>LualineBuffersJump 3<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>4", "<cmd>LualineBuffersJump 4<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>5", "<cmd>LualineBuffersJump 5<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>6", "<cmd>LualineBuffersJump 6<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>7", "<cmd>LualineBuffersJump 7<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>8", "<cmd>LualineBuffersJump 8<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>9", "<cmd>LualineBuffersJump 9<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b>0", "<cmd>LualineBuffersJump 10<CR>")

vim.keymap.set({"n", "i", "v"}, "<C-b><C-1>", "<cmd>LualineBuffersJump 1<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-2>", "<cmd>LualineBuffersJump 2<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-3>", "<cmd>LualineBuffersJump 3<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-4>", "<cmd>LualineBuffersJump 4<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-5>", "<cmd>LualineBuffersJump 5<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-6>", "<cmd>LualineBuffersJump 6<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-7>", "<cmd>LualineBuffersJump 7<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-8>", "<cmd>LualineBuffersJump 8<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-9>", "<cmd>LualineBuffersJump 9<CR>")
vim.keymap.set({"n", "i", "v"}, "<C-b><C-0>", "<cmd>LualineBuffersJump 10<CR>")
