return {
    "nvzone/floaterm",
    dependencies = "nvzone/volt",
    config = function()
        vim.g.floaterm_width = 0.8
        vim.g.floaterm_height = 0.8
        vim.keymap.set("n", "<F1>", ":FloatermToggle<CR>", { desc = "Toggle float term" })
        vim.keymap.set("t", "<F1>", "<C-\\><C-n>:FloatermToggle<CR>", { desc = "Close float term" })
    end,
}
