return {
    {
        "ricardoramirezr/blade-nav.nvim",
        dependencies = {
            "hrsh7th/nvim-cmp",
            { "ms-jpq/coq_nvim", branch = "coq" },
            "saghen/blink.cmp",
        },
        ft = { "blade", "php" },
        opts = {
            close_tag_on_complete = true,
        },
        config = function(_, opts)
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
