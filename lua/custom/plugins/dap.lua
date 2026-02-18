-- Debug Adapter Protocol (DAP) for JavaScript/TypeScript and Python
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- UI for nvim-dap
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',

    -- Mason integration for installing debug adapters
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Virtual text support for showing variable values inline
    'theHamsta/nvim-dap-virtual-text',
  },
  keys = {
    -- Debugging keymaps
    { '<leader>dc', function() require('dap').continue() end, desc = '[D]ebug [C]ontinue' },
    { '<leader>di', function() require('dap').step_into() end, desc = '[D]ebug Step [I]nto' },
    { '<leader>do', function() require('dap').step_over() end, desc = '[D]ebug Step [O]ver' },
    { '<leader>dO', function() require('dap').step_out() end, desc = '[D]ebug Step [O]ut' },
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = '[D]ebug Toggle [B]reakpoint' },
    {
      '<leader>dB',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = '[D]ebug [B]reakpoint Condition',
    },
    { '<leader>dt', function() require('dap').terminate() end, desc = '[D]ebug [T]erminate' },
    { '<leader>dr', function() require('dap').repl.toggle() end, desc = '[D]ebug [R]EPL Toggle' },
    { '<leader>dl', function() require('dap').run_last() end, desc = '[D]ebug Run [L]ast' },

    -- DAP UI keymaps
    { '<leader>du', function() require('dapui').toggle() end, desc = '[D]ebug [U]I Toggle' },
    { '<leader>de', function() require('dapui').eval() end, desc = '[D]ebug [E]val', mode = { 'n', 'v' } },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Mason DAP setup to automatically install debug adapters
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'js-debug-adapter', -- For JavaScript/TypeScript
        'debugpy', -- For Python
      },
    }

    -- DAP UI setup
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Virtual text setup - shows variable values inline
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
    }

    -- Automatically open/close DAP UI
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- JavaScript/TypeScript configuration (js-debug-adapter)
    require('dap').adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'js-debug-adapter',
        args = { '${port}' },
      },
    }

    for _, language in ipairs { 'typescript', 'javascript' } do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Jest Tests',
          runtimeExecutable = 'node',
          runtimeArgs = {
            './node_modules/jest/bin/jest.js',
            '--runInBand',
          },
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          internalConsoleOptions = 'neverOpen',
        },
      }
    end

    -- Python configuration (debugpy)
    dap.adapters.python = {
      type = 'executable',
      command = vim.fn.exepath 'python3', -- Use system python3
      args = { '-m', 'debugpy.adapter' },
    }

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
          -- Try to use virtual environment python first
          local venv_python = vim.fn.getcwd() .. '/.venv/bin/python'
          if vim.fn.filereadable(venv_python) == 1 then return venv_python end
          return 'python3'
        end,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' +')
        end,
        pythonPath = function()
          local venv_python = vim.fn.getcwd() .. '/.venv/bin/python'
          if vim.fn.filereadable(venv_python) == 1 then return venv_python end
          return 'python3'
        end,
      },
      {
        type = 'python',
        request = 'attach',
        name = 'Attach remote',
        connect = function()
          local host = vim.fn.input 'Host [127.0.0.1]: '
          host = host ~= '' and host or '127.0.0.1'
          local port = tonumber(vim.fn.input 'Port [5678]: ') or 5678
          return { host = host, port = port }
        end,
      },
    }

    -- Set breakpoint signs
    vim.fn.sign_define('DapBreakpoint', { text = '🔴', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '🟡', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '🚫', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '📝', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶️', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = '' })
  end,
}
