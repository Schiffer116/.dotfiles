return {
    "rcarriga/nvim-dap-ui",
    dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"},

    config = function()
        require("dapui").setup()
        local dap, dapui = require("dap"), require("dapui")

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        vim.keymap.set("n", '<leader>b', function() require('dap').toggle_breakpoint() end)
        vim.keymap.set("n", '<leader>c', function() require('dap').continue() end)
        vim.keymap.set("n", '<leader>i', function() require('dap').step_into() end)
        vim.keymap.set("n", '<leader>o', function() require('dap').step_over() end)
        vim.keymap.set("n", '<leader>t', function() require('dap').step_out() end)

        dap.adapters.lldb = {
            type = 'executable',
            -- absolute path is important here, otherwise the argument in the `runInTerminal` request will default to $CWD/lldb-vscode
            command = '/usr/bin/lldb-vscode',
            name = "lldb"
        }

        dap.defaults.fallback.externatl_terminal = {
            command = '/usr/local/bin/kitty',
            args = {
                '--hold',
            },
        }

        dap.configurations.cpp = {
            {
                name = "Launch",
                type = "lldb",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
                args = {},
                runInTerminal = true,
            },
        }
    end
}
