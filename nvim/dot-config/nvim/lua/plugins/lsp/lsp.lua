return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
    },
    config = function()
        local keymap = vim.keymap
        local opts = { noremap = true, silent = true }
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local on_attach = function(client, bufnr)
            opts.buffer = bufnr
            opts.desc = "See available code action"
            keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

            opts.desc = "Show documentation for what is under cursor"
            keymap.set("n", "K", vim.lsp.buf.hover, opts)
        end

        local capabilities = cmp_nvim_lsp.default_capabilities()

        vim.lsp.config("prettier", {
            capabilities = capabilities,
            on_attach = on_attach,
        })
        vim.lsp.config("emmet_ls", {
            capabilities = capabilities,
            on_attach = on_attach,
        })
        vim.lsp.config("intelephense", {
            capabilities = capabilities,
            on_attach = on_attach,
        })
        vim.lsp.config("lua_ls", {
            settings = { -- custom settings for lua
                Lua = {
                    workspace = {
                        -- make language server aware of runtime files
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })
    end,
}
