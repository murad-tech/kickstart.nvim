-- Neotest - A framework for running tests in Neovim
-- Supports Jest (JS/TS) and Pytest (Python)

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- Test adapters
    'nvim-neotest/neotest-jest',
    'nvim-neotest/neotest-python',
  },
  keys = {
    { '<leader>tt', function() require('neotest').run.run() end, desc = 'Run nearest test' },
    { '<leader>tf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run current file' },
    { '<leader>ta', function() require('neotest').run.run(vim.fn.getcwd()) end, desc = 'Run all tests' },
    { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle test summary' },
    { '<leader>to', function() require('neotest').output.open { enter = true } end, desc = 'Open test output' },
    { '<leader>tp', function() require('neotest').output_panel.toggle() end, desc = 'Toggle output panel' },
    { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop test' },
    { '<leader>tw', function() require('neotest').watch.toggle() end, desc = 'Toggle watch mode' },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestConfigFile = 'jest.config.js',
          env = { CI = true },
          cwd = function() return vim.fn.getcwd() end,
        },
        require 'neotest-python' {
          dap = { justMyCode = false },
          runner = 'pytest',
          python = '.venv/bin/python',
        },
      },
    }
  end,
}
