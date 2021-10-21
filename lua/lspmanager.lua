lspmanager = {}

local servers = require("lspmanager.servers")
local configs = require("lspconfig/configs")
local jobs = require("lspmanager.jobs")
local get_path = require("lspmanager.utilities").get_path

local servers_list = require("lspmanager.utilities").servers_list

lspmanager.setup = function()
    lspmanager.setup_servers(false, nil)
end

lspmanager.is_lsp_installed = function(lsp)
    return vim.fn.isdirectory(get_path(lsp))
end

lspmanager.available_servers = function()
    return vim.tbl_keys(servers)
end

lspmanager.installed_servers = function(opts)
    opts = opts or {}
    local res = {}
    if opts.insert_key_all then
        table.insert(res, "all")
    end
    local installed = vim.tbl_filter(function(key)
        return lspmanager.is_lsp_installed(key) == 1
    end, lspmanager.available_servers())
    vim.list_extend(res, installed)
    return res
end

lspmanager.setup_servers = function(is_install, lsp)
    if is_install then
        local server_config = servers[lsp].config
        local path = get_path(lsp)

        local config = vim.tbl_deep_extend("keep", server_config, { default_config = { cmd_cwd = path } })
        if config.default_config.cmd then
            local executable = config.default_config.cmd[1]
            if vim.regex([[\.\/]]):match_str(executable) then
                config.default_config.cmd[1] = path .. "/" .. executable
            end

            if lsp == "sumneko_lua" then
                local main = config.default_config.cmd[3]
                config.default_config.cmd[3] = path .. "/" .. main
            end
        end
        configs[lsp] = config

        if require("lspmanager.utilities").is_vscode_lsp(lsp) then
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            require("lspconfig")[lsp].setup({
                capabilities = capabilities,
            })
        else
            require("lspconfig")[lsp].setup({})
        end
        return
    end
    for _, lsp in pairs(servers_list) do
        local path = get_path(lsp)
        local server_config = servers[lsp].config
        if lspmanager.is_lsp_installed(lsp) == 1 and not configs[lsp] then
            local config = vim.tbl_deep_extend("keep", server_config, { default_config = { cmd_cwd = path } })
            if config.default_config.cmd then
                local executable = config.default_config.cmd[1]
                if vim.regex([[\.\/]]):match_str(executable) then
                    config.default_config.cmd[1] = path .. "/" .. executable
                end
                if lsp == "sumneko_lua" then
                    local main = config.default_config.cmd[3]
                    config.default_config.cmd[3] = path .. "/" .. main
                end
            end
            configs[lsp] = config

            if require("lspmanager.utilities").is_vscode_lsp(lsp) then
                local capabilities = vim.lsp.protocol.make_client_capabilities()
                capabilities.textDocument.completion.completionItem.snippetSupport = true

                require("lspconfig")[lsp].setup({
                    capabilities = capabilities,
                })
            else
                require("lspconfig")[lsp].setup({})
            end
        end
    end
    require("lspconfig").gdscript.setup({})
end

lspmanager.install = function(lsp)
    if not lsp or lsp == "" then
        local filetype = vim.bo.filetype

        if vim.api.nvim_buf_get_name(0) == "" or filetype == "" then
            error("No file attached in current buffer, aborting...")
        end

		local available_for_filetype = require("lspmanager.utilities").available_for_filetype()
		print(vim.inspect(available_for_filetype))

        if #available_for_filetype == 1 then
            for _, config in pairs(vim.lsp.get_active_clients()) do
                if config.name == available_for_filetype[1] then
                    print("Lsp for " .. filetype .. " is already installed and running")
                    return
                end
            end

            local path = get_path(available_for_filetype[1])
            vim.fn.mkdir(path, "p")

            print("installing " .. available_for_filetype[1] .. " for current file type...")
            jobs.installation_job(available_for_filetype[1], path, false)
        elseif #available_for_filetype == 0 then
            error("no server found for filetype " .. filetype)
        elseif #available_for_filetype > 1 then
            error(
                "multiple servers found ("
                    .. table.concat(available_for_filetype, "/")
                    .. "), please install one of them"
            )
        end

        return
    end

    if not servers[lsp] then
        error("could not find LSP " .. lsp)
    end

    for _, config in pairs(vim.lsp.get_active_clients()) do
        if config.name == lsp then
            print("Lsp for " .. lsp .. " is already installed and running")
            return
        end
    end

    local path = get_path(lsp)
    vim.fn.mkdir(path, "p")

    print("Installing " .. lsp .. "...")
    jobs.installation_job(lsp, path, false)
end

lspmanager.uninstall = function(lsp)
    if not servers[lsp] then
        error("could not find LSP " .. lsp)
    end

    if lspmanager.is_lsp_installed(lsp) == 0 then
        error(lsp .. " is not installed")
    end

    local path = get_path(lsp)
    if vim.fn.delete(path, "rf") == 0 then
        vim.notify("Successfully uninstalled " .. lsp)
    else
        error("failed to uninstall " .. lsp)
    end
end

lspmanager.update = function(lsp)
    if lsp == "all" then
        local installed = lspmanager.installed_servers()
        for _, server in pairs(installed) do
            lspmanager.update(server)
        end
        return
    end

    if not servers[lsp] then
        error("Could not find LSP " .. lsp)
    end

    if lspmanager.is_lsp_installed(lsp) == 0 then
        error(lsp .. " is not installed")
    end

    local path = get_path(lsp)

    print("Looking for " .. lsp .. " updates...")

    jobs.update_job(lsp, path)
end

return lspmanager
