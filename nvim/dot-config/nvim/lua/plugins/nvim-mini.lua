return {
    "nvim-mini/mini.nvim",
    version = "*",
    config = function()
        local gen_loader = require("mini.snippets").gen_loader
        require("mini.icons").setup({})
        require("mini.pairs").setup({})
        require("mini.comment").setup({})
        require("mini.splitjoin").setup({})
        require("mini.surround").setup({})
        require("mini.ai").setup({})
        require("mini.files").setup({})
        require("mini.cursorword").setup({})
        require("mini.notify").setup({})
        require("mini.statusline").setup({})
        require("mini.tabline").setup({})
    end,
}
-- "Two words"
