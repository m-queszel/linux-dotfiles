return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    -- Due to recent changes, the .configs needs to be .config- otherwise, an error will be thrown
    main = "nvim-treesitter.configs",
    init = function()
        vim.filetype.add({
            pattern = {
                [".*%.blade%.php"] = "blade",
            },
        })
    end,
    opts = {
        ensure_installed = {
            "intelephense",
            "emmet_ls",
            "prettier",
            "stylua",
            "lua_ls",
        },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = true,
        },
        indent = { enable = true },
    },
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "blade",
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
