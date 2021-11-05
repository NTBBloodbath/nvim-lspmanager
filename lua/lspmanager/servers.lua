local servers = {
    ["angularls"] = require("lspmanager.servers.angularls"),
    ["bashls"] = require("lspmanager.servers.bashls"),
    ["clangd"] = require("lspmanager.servers.clangd"),
    ["clojure_lsp"] = require("lspmanager.servers.clojure_lsp"),
    ["cmake"] = require("lspmanager.servers.cmake"),
    ["cssls"] = require("lspmanager.servers.cssls"),
    ["dockerls"] = require("lspmanager.servers.dockerls"),
    ["elixirls"] = require("lspmanager.servers.elixirls"),
    ["elmls"] = require("lspmanager.servers.elmls"),
    ["emmet_ls"] = require("lspmanager.servers.emmet_ls"),
    ["fsautocomplete"] = require("lspmanager.servers.fsautocomplete"),
    ["gopls"] = require("lspmanager.servers.gopls"),
    ["hls"] = require("lspmanager.servers.hls"),
    ["html"] = require("lspmanager.servers.html"),
    ["jsonls"] = require("lspmanager.servers.jsonls"),
    ["kotlinls"] = require("lspmanager.servers.kotlinls"),
    ["omnisharp"] = require("lspmanager.servers.omnisharp"),
    ["purescriptls"] = require("lspmanager.servers.purescriptls"),
    ["pyright"] = require("lspmanager.servers.pyright"),
    ["rust_analyzer"] = require("lspmanager.servers.rust_analyzer"),
    ["solang"] = require("lspmanager.servers.solang"),
    ["sumneko_lua"] = require("lspmanager.servers.sumneko_lua"),
    ["svelte"] = require("lspmanager.servers.svelte"),
    ["tailwindcss"] = require("lspmanager.servers.tailwindcss"),
    ["terraformls"] = require("lspmanager.servers.terraformls"),
    ["texlab"] = require("lspmanager.servers.texlab"),
    ["tsserver"] = require("lspmanager.servers.tsserver"),
    ["vimls"] = require("lspmanager.servers.vimls"),
    ["volar"] = require("lspmanager.servers.volar"),
    ["vuels"] = require("lspmanager.servers.vuels"),
}

return {
    get = function(server_name)
        if server_name then
            return servers[server_name]
        end
        return servers
    end,

    set = function(user_configs)
        vim.validate({ user_configs = { user_configs, "table" } })

        for name, configuration in pairs(user_configs) do
            servers[name] = vim.tbl_deep_extend("force", servers[name], {
                config = {
                    default_config = configuration,
                },
            })
        end

        return servers
    end,
}
