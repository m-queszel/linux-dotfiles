return {
    {
        "ricardoramirezr/blade-nav.nvim",
        dependencies = { -- totally optional
            "hrsh7th/nvim-cmp", -- if using nvim-cmp
            { "ms-jpq/coq_nvim", branch = "coq" }, -- if using coq
            "saghen/blink.cmp", -- if using blink.cmp
        },
        ft = { "blade", "php" }, -- optional, improves startup time
        opts = {
            -- This applies for nvim-cmp and coq, for blink refer to the configuration of this plugin
            close_tag_on_complete = true, -- default: true
        },
        config = function(_, opts)
            -- Compatibility fix for newer nvim-treesitter (ts_utils module was removed)
            local ts_utils_mock = {}
            function ts_utils_mock.get_node_at_cursor()
                local bufnr = vim.api.nvim_get_current_buf()
                ---@diagnostic disable-next-line: deprecated
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                row = row - 1
                local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
                if not ok or not parser then
                    return nil
                end
                local tree = parser:parse()[1]
                if not tree then
                    return nil
                end
                return tree:root():named_descendant_for_range(row, col, row, col)
            end
            package.preload["nvim-treesitter.ts_utils"] = function()
                return ts_utils_mock
            end
        end,
    },
}
