vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", "\"_dP")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+y")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<leader>h", "<C-w>h")
vim.keymap.set("n", "<leader>j", "<C-w>j")
vim.keymap.set("n", "<leader>k", "<C-w>k")
vim.keymap.set("n", "<leader>l", "<C-w>l")

vim.keymap.set("n", "<leader>H", "5<C-w><")
vim.keymap.set("n", "<leader>J", "5<C-w>-")
vim.keymap.set("n", "<leader>K", "5<C-w>+")
vim.keymap.set("n", "<leader>L", "5<C-w>>")

vim.keymap.set("n", "<leader><C-H>", "<C-w>H")
vim.keymap.set("n", "<leader><C-J>", "<C-w>J")
vim.keymap.set("n", "<leader><C-K>", "<C-w>K")
vim.keymap.set("n", "<leader><C-L>", "<C-w>L")

vim.keymap.set("n", "<leader>.", ":bn<CR>")
vim.keymap.set("n", "<leader>,", ":bp<CR>")
