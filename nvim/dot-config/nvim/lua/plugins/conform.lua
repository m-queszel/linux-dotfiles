return {
    "stevearc/conform.nvim",
    opts = {},
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                rust = { "rustfmt" },
                javascript = { "prettierd", "prettier" },
            },
            formatters = {
                stylua = {
                    prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" },
                },
                isort = {
                    prepend_args = { "--profile", "black" },
                },
                prettier = {
                    prepend_args = { "--tab-width", "4" },
                },
            },
        })
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function(args)
                require("conform").format({ bufnr = args.buf })
            end,
        })
    end,
}
