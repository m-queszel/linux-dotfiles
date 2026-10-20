vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- When text is wrapped, move by terminal rows, not lines, unless a count is provided.
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Reselect visual selection after indenting.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
-- Maintain the cursor position when yanking a visual selection.
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set("v", "y", "myy`y")

-- Disable annoying command line typo.
vim.keymap.set("n", "q:", ":q")

-- Paste replace visual selection without copying it.
vim.keymap.set("v", "p", '"_dP')

-- Easy insertion of a trailing ; or , from insert mode.
vim.keymap.set("i", ";;", "<Esc>A;")
vim.keymap.set("i", ",,", "<Esc>A,")

-- Quickly clear search highlighting.
vim.keymap.set("n", "<Leader>k", ":nohlsearch<CR>")

-- Open the current file in the default program (on Mac this should just be just `open`).
vim.keymap.set("n", "<Leader>x", ":!xdg-open %<CR><CR>")

-- Move lines up and down.
vim.keymap.set("i", "<A-j>", "<Esc>:move .+1<CR>==gi")
vim.keymap.set("i", "<A-k>", "<Esc>:move .-2<CR>==gi")
vim.keymap.set("n", "<A-j>", ":move .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":move .-2<CR>==")
vim.keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv")

vim.keymap.set("n", "<leader>fe", ":lua MiniFiles.open()<CR>")
vim.keymap.set("n", "<leader>fE", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlights text when yanking",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move focus to the right window" })

vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<CR>", { desc = "Move focus to the left window" })
vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<CR>", { desc = "Move focus to the lower window" })
vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<CR>", { desc = "Move focus to the upper window" })
vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<CR>", { desc = "Move focus to the right window" })

-- Gitsigns
vim.keymap.set("n", "]h", ":Gitsigns next_hunk<CR>", { desc = "Next Hunk" })
vim.keymap.set("n", "[h", ":Gitsigns prev_hunk<CR>", { desc = "Prev Hunk" })
vim.keymap.set("n", "<leader>gs", function()
    require("gitsigns").stage_hunk()
    require("gitsigns").refresh()
end, { desc = "Stage Hunk" })
vim.keymap.set("n", "<leader>gS", function()
    require("gitsigns").undo_stage_hunk()
    require("gitsigns").refresh()
end, { desc = "Undo Stage Hunk" })
vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview Hunk" })
vim.keymap.set("n", "<leader>gb", ":Gitsigns blame_line<CR>", { desc = "Blame Line" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Previous Buffer" })
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete Buffer" })
