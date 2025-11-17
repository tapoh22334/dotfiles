-- editor.lua - Modern editor plugins

return {
  -- Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors = true,
        dim_inactive = {
          enabled = false,
          shade = "dark",
          percentage = 0.15,
        },
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = false,
          neo_tree = true,
          treesitter = true,
          notify = false,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
            inlay_hints = {
              background = true,
            },
          },
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'lua', 'vim', 'vimdoc',
          'python', 'rust', 'go', 'c', 'cpp',
          'javascript', 'typescript', 'tsx', 'json',
          'html', 'css', 'markdown',
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<S-CR>',
            node_decremental = '<BS>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
        },
      })
    end,
  },

  -- Neo-tree file explorer (replaces NERDTree)
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '<leader>n', ':Neotree toggle<CR>', desc = 'Toggle Neo-tree' },
      { '<leader>e', ':Neotree reveal<CR>', desc = 'Reveal current file' },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = 'rounded',
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        position = 'left',
        width = 30,
      },
    },
  },

  -- fzf-lua fuzzy finder (replaces FZF and Telescope)
  {
    'ibhagwan/fzf-lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    cmd = 'FzfLua',
    keys = {
      { '<leader>f', '<cmd>FzfLua files<cr>', desc = 'Find files' },
      { '<leader>F', '<cmd>FzfLua files cwd=~<cr>', desc = 'Find files (home)' },
      { '<leader>g', '<cmd>FzfLua live_grep<cr>', desc = 'Live grep' },
      { '<leader>b', '<cmd>FzfLua buffers<cr>', desc = 'Buffers' },
      { '<leader>h', '<cmd>FzfLua help_tags<cr>', desc = 'Help tags' },
      { '<leader>r', '<cmd>FzfLua oldfiles<cr>', desc = 'Recent files' },
      { '<leader>s', '<cmd>FzfLua lsp_document_symbols<cr>', desc = 'Document symbols' },
      { '<leader>S', '<cmd>FzfLua lsp_workspace_symbols<cr>', desc = 'Workspace symbols' },
    },
    config = function()
      require('fzf-lua').setup({
        winopts = {
          height = 0.85,
          width = 0.80,
          preview = {
            layout = 'horizontal',
            horizontal = 'right:55%',
          },
        },
        keymap = {
          builtin = {
            ['<C-j>'] = 'down',
            ['<C-k>'] = 'up',
          },
          fzf = {
            ['ctrl-q'] = 'select-all+accept',
          },
        },
        files = {
          find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
          rg_opts = "--color=never --files --hidden --follow -g '!.git'",
        },
      })
    end,
  },

  -- Aerial code outline (replaces Tagbar)
  {
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    cmd = { 'AerialToggle', 'AerialOpen' },
    keys = {
      { '<leader>t', '<cmd>AerialToggle<cr>', desc = 'Toggle Aerial' },
      { '[a', '<cmd>AerialPrev<cr>', desc = 'Previous symbol' },
      { ']a', '<cmd>AerialNext<cr>', desc = 'Next symbol' },
    },
    opts = {
      backends = { 'lsp', 'treesitter', 'markdown' },
      layout = {
        default_direction = 'prefer_left',
        placement = 'edge',
      },
      attach_mode = 'global',
      close_on_select = false,
      highlight_on_hover = true,
      autojump = false,
    },
  },

  -- Lualine status line (replaces vim-airline)
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = {
        theme = 'catppuccin',
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        globalstatus = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    },
  },

  -- Gitsigns for git integration
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Next hunk' })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Previous hunk' })

        -- Actions
        map('n', '<leader>hs', gs.stage_hunk, { desc = 'Stage hunk' })
        map('n', '<leader>hr', gs.reset_hunk, { desc = 'Reset hunk' })
        map('n', '<leader>hS', gs.stage_buffer, { desc = 'Stage buffer' })
        map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
        map('n', '<leader>hR', gs.reset_buffer, { desc = 'Reset buffer' })
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
        map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, { desc = 'Blame line' })
        map('n', '<leader>hd', gs.diffthis, { desc = 'Diff this' })
      end,
    },
  },

  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = {
        char = '│',
      },
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
      },
    },
  },

  -- Auto pairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,
        ts_config = {
          lua = { 'string' },
          javascript = { 'template_string' },
        },
      })

      -- Integration with nvim-cmp
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- Comment.nvim for better commenting
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gc', mode = { 'n', 'v' }, desc = 'Comment toggle linewise' },
      { 'gb', mode = { 'n', 'v' }, desc = 'Comment toggle blockwise' },
    },
    opts = {
      toggler = {
        line = 'gcc',
        block = 'gbc',
      },
      opleader = {
        line = 'gc',
        block = 'gb',
      },
    },
  },

  -- Surround text objects
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  -- Which-key for keybinding hints
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      local wk = require('which-key')
      wk.setup({
        plugins = {
          spelling = {
            enabled = true,
          },
        },
      })

      -- Register key groups
      wk.add({
        { "<leader>h", group = "Git hunks" },
        { "<leader>w", group = "Wiki" },
      })
    end,
  },

  -- Open browser
  {
    'tyru/open-browser.vim',
    keys = {
      { 'gx', '<Plug>(openbrowser-smart-search)', mode = 'n', desc = 'Open browser' },
      { 'gx', '<Plug>(openbrowser-smart-search)', mode = 'v', desc = 'Open browser' },
    },
    init = function()
      vim.g.netrw_nogx = 1
    end,
  },

  -- Goyo (distraction-free writing)
  {
    'junegunn/goyo.vim',
    cmd = 'Goyo',
  },

  -- Vimwiki
  {
    'vimwiki/vimwiki',
    keys = { '<leader>ww', '<leader>wt' },
    init = function()
      vim.g.vimwiki_list = {
        { path = '~/wiki/', syntax = 'markdown', index = 'Home', ext = '.md' }
      }
    end,
  },

  -- EasyAlign
  {
    'junegunn/vim-easy-align',
    keys = {
      { 'ga', '<Plug>(EasyAlign)', mode = 'x', desc = 'EasyAlign' },
      { 'ga', '<Plug>(EasyAlign)', mode = 'n', desc = 'EasyAlign' },
    },
  },

  -- Markdown preview
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && npm install',
    ft = { 'markdown' },
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
  },

  -- Emmet (still useful for HTML/CSS)
  {
    'mattn/emmet-vim',
    ft = { 'html', 'css', 'javascript', 'typescript' },
    init = function()
      vim.g.user_emmet_leader_key = '<c-t>'
    end,
  },
}
