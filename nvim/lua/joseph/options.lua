vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wildmode = "longest:full,full"
vim.opt.completeopt = "menuone,longest,preview"

vim.opt.title = true
vim.opt.mouse = "a"

vim.opt.termguicolors = true

vim.opt.spell = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·" }
vim.opt.fillchars:append({ eob = " " })

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.clipboard = "unnamedplus"
vim.opt.signcolumn = "yes:1"

vim.opt.confirm = true

vim.opt.signcolumn = "yes:2"

vim.opt.undofile = true
vim.opt.backup = true
vim.opt.backupdir:remove(".")
