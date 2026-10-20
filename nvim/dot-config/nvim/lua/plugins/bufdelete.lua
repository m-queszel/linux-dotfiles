return {
    "famiu/bufdelete.nvim",
    -- Lazy load when these keybindings are pressed
    keys = {
        { "<leader>bd", "<cmd>Bdelete<cr>", desc = "Delete Buffer" },
        { "<leader>bD", "<cmd>Bdelete!<cr>", desc = "Delete Buffer (Force)" },
    },
}
