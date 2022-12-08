-- vim: et

--require('mason').setup({
--    ui = {
--        icons = {
--            package_instaleld = 'x',
--            package_pending = '.',
--            package_uninstalled = ' ',
--        }
--    }
--})

require('config-local').setup({
    config_files = {'.vimrc', '.vimrc.lua'},
    hashfile = vim.fn.stdpath('data') .. '/config-local',
    autocommands_create = true,
    commands_create = true,
    silent = true,
    lookup_parents = true,
})

local lspconf = require('lspconfig')
local lsputil = require('lspconfig/util')
local lspconf_configs = require('lspconfig/configs')
local lspsignature = require('lsp_signature')
local lsp_status = require('lsp-status')
local lsp_inlay_hints = require('lsp-inlayhints')

lsp_status.config({
    status_symbol = 'f',
    indicator_separator = ':',
    indicator_errors = 'E',
    indicator_warnings = 'W',
    indicator_hints = 'H',
    indicator_info = 'I',
    indicator_ok = ':-)',
    diagnostics = false,  -- already showing by lualine
})
lsp_status.register_progress()

require('nvim-treesitter.configs').setup {
    ensure_installed = {'c', 'lua', 'go', 'gomod', 'python'},
    sync_install = false,
    auto_install = true,
    ignore_install = { help },
    highlight = {
        enable = true,
        disable = {},  -- e.g. rust
        additional_vim_regex_highlighting = false,  -- can also be e.g. {python}
    },
    rainbow = {
        enable = true,
        extended_mode = true,
        max_file_lines = nil,
    },
}
require('hlargs').setup()

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
        virtual_text = true,
        signs = true,
        update_in_insert = true,
        -- display_diagnostic_autocmds = { "InsertLeave" },
    }
)

require('lualine').setup({
    options = {
        theme = 'onedark',  -- also good "onedark", "codedark", "material"
        icons_enabled = false,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = ' >', right = '| ' },
        globalstatus = false,  -- we want on each window
        refresh = {
            statusline = 10,
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {{
            'diagnostics',
            update_in_insert = true,
            always_visible = false,
            diagnostics_color = {
                -- mcsl: def are DiagnosticsError, *Warning, *Hint and *Info
                error = { bg = 1, fg = 'yellow'},
                warning = { bg = 3, fg = 'yellow'},
                info = {bg = 4, fg = 'white'},
                hint = {bg = none, fg = 'lightgrey'},
            },
        }},
        lualine_c = {{
            'filename',
            path = 1, -- justname(0), relative(1)
            shorting_target = 60, -- dont take more thatn 60 chars
        }},
        -- lualine_x = {'require("lsp-status").status()', 'filetype'},       -- encoding(utf-8), fileformat(unix)
        lualine_x = {
            function()
                local ts_utils = require('nvim-treesitter.ts_utils')
                local query = require('nvim-treesitter.query')
                local curnode = ts_utils.get_node_at_cursor() or ''

                while curnode do
                    if curnode:type() == 'function_declaration' then
                        break
                    end
                    curnode = curnode:parent()
                end

                if not curnode then return '' end

                local meth = vim.treesitter.query.get_node_text(curnode:child(1), 0)
                return 'f(' .. meth .. ')'

                -- return z
                -- return ts_utils.get_node_text(curnode:child(1))[1]
                -- return require('nvim-treesitter').statusline()
            end,
        },
        lualine_y = {'progress'},
        lualine_z = {'location'},
    },
    inactive_sections = {
        lualine_a = {'mode'},
        lualine_b = {{
            'diagnostics',
            update_in_insert = true,
            diagnostics_color = {
                -- mcsl: def are DiagnosticsError, *Warning, *Hint and *Info
                error = { bg = 1, fg = 'yellow'},
                warning = { bg = 3, fg = 'yellow'},
                info = {bg = 4, fg = 'white'},
                hint = {bg = none, fg = 'lightgrey'},
            },
        }},
        lualine_c = {{
            'filename',
            path = 1, -- justname(0), relative(1)
            shorting_target = 60,
        }},
        -- lualine_x = {'require("lsp-status").status()', 'filetype'},
        lualine_y = {},
        lualine_z = {},
    },
    extensions = {
        'nerdtree',
        'quickfix',
    },
})
vim.opt.showmode = false  -- not requre to show mode on bottom with lualine

require('fidget').setup({
    text = {
        done = '+',
        spinner = 'dots',
    },
    align = {
        -- bottom = false,
    },
    timer = {
        spinner_rate = 50,
    },
})

require('nvim-lightbulb').setup({
    autocmd = {enabled = false},
    sign = {
        enabled = false,
        priority = 1,
    },
    float = {
        enabled = false,
        text = '!!!',
    },
    virtual_text = {
        enabled = false,
        text = '!!!',
    },
    status_text = {
        enabled = true,
        text = 'S-F1',
        text_unavailable = 'no code actions'
    },
})


local use_satellite = true

if vim.api.nvim_win_get_option(0, 'diff') then use_satellite = false end

if use_satellite then
    require('satellite').setup({
        current_only = false,
        winblend = 0,
        zindex = 40,
        excluded_filetypes = {},
        width = 2,
        handlers = {
            search = {
                enable = true,
            },
            diagnostic = {
                enable = true,
            },
            gitsigns = {
                enable = true,
            },
            marks = {
                enable = true,
                show_builtins = false, -- shows the builtin marks like [ ] < >
            },
        },
    })
end

require('trouble').setup({
    position = 'bottom',
    icons = false,
    fold_open = "v", -- icon used for open folds
    fold_closed = ">", -- icon used for closed folds
    indent_lines = false, -- add an indent guide below the fold icons
    signs = {
        -- icons / text used for a diagnostic
        error = "E",
        warning = "W",
        hint = "H",
        information = "I",
        other = "?",
    },
    use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
    auto_open = false,
    auto_close = false,
    auto_fold = false,
    auto_preview = false,
    auto_jump = {},
})

require('luasnip/loaders/from_vscode').load({
    paths = {
        '~/.local/share/nvim/plugged/friendly-snippets',
    },
})

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local luasnip = require('luasnip')

local cmp = require('cmp')
cmp.setup({
    completion = {
        autocomplete = false,
        completeopt = 'menu,menuone,noinsert'
    },
    preselect = cmp.PreselectMode.None,
    snippet = {
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body)
            require('luasnip').lsp_expand(args.body)
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ["<Down>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
        ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i", "c" }),
        --['<S-Tab>'] = cmp.mapping.select_prev_item(),
        --['<Tab>'] = cmp.mapping.select_next_item(),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if false and cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if false and cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete({
            reason = cmp.ContextReason.Auto,
        }), { 'i', 'c' }),
        ['<M-Space>'] = cmp.mapping(cmp.mapping.complete({
            reason = cmp.ContextReason.Manual,
        }), { 'i', 'c' }),
        ['<C-e>'] = cmp.mapping.close(),
        ['<Enter>'] = cmp.mapping.confirm({
            -- behavior = cmp.ConfirmBehavior.Insert,
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
        -- ['C-y'] = cmp.mapping.confirm({select = true}),
    },

    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        -- { name = 'vsnip' },
        { name = 'path' },
        -- { name = 'nvim_lsp_signature_help' },
    }, {
        { name = 'buffer' },
    }), 
})

cmp.setup.cmdline(':', {
    sources = {
        {name = 'cmdline'},
    },
})

cmp.setup.cmdline('/', {
    sources = {{name = 'buffer'}},
})

-- lspsignature.setup({
--     bind = true,
--     handler_opts = {
--         border = 'single',
--     },
--     max_width = 120,
--     hint_enable = false,
--     hint_prefix = '(arg) ',
--     hint_scheme = 'Comment',
--     hi_parameter = 'IncSearch',
--     padding = '',
--     floating_window = true,
--     fix_pos = false, -- breaks it
--     floating_window_off_x = -1,
--     floating_window_off_y = 0,
--     extra_trigger_chars = {},
--     timer_interval = 1, -- default 200
--     always_trigger = false,
--     toggle_key = '<A-s>'
-- })

lsp_inlay_hints.setup()

if 1 then
local capabilities = lsp_status.capabilities
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)


local on_attach = function(client, bufnr)
    local bufopts = {noremap = true, silent = true}

    local function on_list(options)
        vim.fn.setqflist({}, ' ', options)
        vim.cmd('Trouble quickfix')
    end

    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    --vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gd', '<CMD>Telescope lsp_definitions fname_width=60<CR>')
    vim.keymap.set('n', 'gtd', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    --vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gi', '<CMD>Telescope lsp_implementations fname_width=60<CR>', bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', 'rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', 'ca', '<CMD>CodeActionMenu<CR>', bufopts)
    --vim.keymap.set('n', 'gr', '<CMD>Trouble lsp_references<CR>', bufopts)
    vim.keymap.set('n', 'gR', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'gr', '<CMD>Telescope lsp_references fname_width=60<CR>', bufopts)
    vim.keymap.set('n', 'gc', '<CMD>Telescope lsp_incoming_calls fname_width=60<CR>', bufopts)
    --vim.keymap.set('n', 'gr', '<CMD>lua vim.lsp.buf.references(); vim.api.nvim_command("cclose")<CR>', bufopts)
    --vim.keymap.set('n', 'gr', function() vim.lsp.buf.references(nil, {}) end, {noremap=true, silent=true})
    --vim.keymap.set('n', 'gr', function() vim.lsp.buf.references(nil, {on_list=on_list}) end, bufopts)
    --vim.keymap.set('n', 'gr', function() vim.lsp.buf.references(nil, {on_list=on_list}) end, bufopts)
    vim.keymap.set('n', 'f', function() vim.lsp.buf.format(); print('formatted') end, bufopts)

    vim.keymap.set('n', 'T', '<CMD>Telescope<CR>')

    -- lsp_status.on_attach(client, bufnr)
    -- lspsignature.on_attach(client, bufnr)
    lsp_inlay_hints.on_attach(client, bufnr)
end

lspconf.gopls.setup({
    -- cmd = {'gopls', '-vv', 'serve', '-rpc.trace', '-logfile=/tmp/gopls.log'},
    cmd = {'/home/mocksoul/workspace/gopls/gopls/gopls', '-remote=unix;/run/user/1000/gopls-main', 'serve'},
    filetypes = {'go', 'gomod'},
    root_dir = lsputil.root_pattern('go.work', 'go.mod', '.git', '.golangci.yaml'),
    settings = {
        gopls = {
            ['local'] = 'a.yandex-team.ru',
            gofumpt = true,
            memoryMode = 'DegradeClosed',
            analyses = {
                asmdecl = true,
                atomic = true,
                atomicalign = true,
                bools = true,
                cgocall = true,
                composites = true,
                copylocks = true,
                deepequalerrors = true,
                embed = true,
                errorsas = true,
                fieldalignment = true, -- not enabled by default<F11>
                httpresponse = true,
                ifaceassert = true,
                infertypeargs = true,
                loopclosure = true,
                lostcancel = true,
                nilfunc = true,
                nilness = true, -- not enabled by default
                printf = true,
                shadow = true,
                shift = true,
                simplifycompositelit = true,
                simplifyrange = true,
                simplifyslice = true,
                sortslice = true,
                stdmethods = true,
                stringintconv = true,
                structtag = true,
                testinggoroutine = true,
                tests = true,
                timeformat = true,
                unmarshal = true,
                unreachable = true,
                unsafeptr = true,
                unusedparams = true, -- not enabled by default
                unusedresult = true,
                unusedwrite = true, -- not enabled by default
                useany = true, -- not enabled by default
                fillreturns = true,
                nonewvars = true,
                noresultvalues = true,
                undeclaredname = true,
                unusedvariable = true,
                fillstruct = true,
                stubmethods = true,
            },
            codelenses = {
                tidy = false,
                gc_details = true,
                vendor = false,
                upgrade_dependency = false,
                test = false,
                regenerate_cgo = false,
                generate = true,
            },
            staticcheck = true,
            expandWorkspaceToModule = true,
            usePlaceholders = true,
            -- hoverKind = 'Structured', -- default: FullDocumentation
            linksInHover = false,
            -- importCacheFilters = {
            --     '-', '+internal'
            -- },
            -- directoryFilters = {
            --     '-',
            --     '+/home/mocksoul/workspace/noc/arc/arcadia/noc/invapi'
            -- },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
        },
    },
    on_attach = on_attach,
    capabilities = capabilities,
})

-- local rustopts = {
--
-- }
-- lspconf.rust_analyzer.setup({
--     on_attach=on_attach,
--     settings = {
--         ['rust-analyzer'] = {
--             imports = {
--                 granularity = {
--                     group = 'module',
--                 },
--                 prefix = 'self',
--             },
--             cargo = {
--                 buildScripts = {
--                     enable = true,
--                 },
--             },
--             procMacro = {
--                 enable = true,
--             },
--             checkOnSave = {
--                 command = 'clippy',
--             },
--         },
--     },
-- })

function GoOrgImports(wait_ms)
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
        if r.edit then
            vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
        else
            vim.lsp.buf.execute_command(r.command)
        end
        end
    end
end
else
    function GoOrgImports(wait_ms) end
end

lspconf.golangci_lint_ls.setup({
    cmd = {'golangci-lint-langserver'},
    root_dir = lsputil.root_pattern('go.work', 'go.mod', '.git', '.golangci.yaml'),
    init_options = {
        command = {
            'golangci-lint', 'run',
            '--allow-parallel-runners', '--out-format', 'json',
            '--max-issues-per-linter', '0', '--max-same-issues', '0',
            '-E', 'revive',
        },
        -- command = {'golangci-lint', 'run', '--out-format', 'json', '--max-issues-per-linter', '0', '--max-same-issues', '0'},
        -- command = {'golangi-lint', 'run', '--out-format', 'json' },
    },
    filetypes = {'go', 'gomod'},
})

local autopairs = require('nvim-autopairs')

autopairs.setup({
    -- fast_wrap = {}, -- use default config
    -- fast_wrap = {
    --   map = '<M-e>',
    --   chars = { '{', '[', '(', '"', "'" },
    --   end_key = '$',
    --   keys = 'qwertyuiopzxcvbnmasdfghjkl',
    --   check_comma = true,
    --   highlight = 'Search',
    --   highlight_grey='Comment',
    --   pattern = [=[[%'%"%)%>%]%)%}%,]{mcsl-delete-me}]=],
    -- },
})

local surround = require('nvim-surround')
surround.setup()

require('nvim-tree').setup({
    hijack_cursor = true,
    view = {
        adaptive_size = false,
        hide_root_folder = true,
        width = 40,
        signcolumn = 'yes',
        mappings = {
            list = {
                { key = '-', action = 'dir_up' }, -- <C-]> cd
                { key = '<C-y>', action = 'vsplit' },
            },
        },
    },
    renderer = {
        highlight_opened_files = 'NvimTreeOpenedFile',
        icons = {
            webdev_colors = true,
            symlink_arrow = ' -> ',
            padding = ' ',
            glyphs = {
                default = '-',
                symlink = 'l',
                bookmark = 'b',
                folder = {
                    arrow_closed = ' ',
                    arrow_open = ' ',
                    default = '-',
                    open = '>',
                    empty = ' ',
                    empty_open = ' ',
                    symlink = ' ',
                    symlink_open = ' ',
                },
            },
        },
    },
    diagnostics = {
        enable = true,
        show_on_dirs = true,
        icons = {
            error = 'E',
            warning = 'W',
            info = 'I',
            hint = 'H',
        }
    },
    actions = {
        open_file = {
            quit_on_open = true,
        },
    },
})

require('telescope').setup({
    defaults = {
        path_display = function(opts, path) 
            local path = path:gsub('/home/mocksoul/workspace/noc/arc/arcadia/library/go/', 'LIB:')
            --local path = path:gsub('/home/mocksoul/workspace/noc/arc/arcadia/noc/invapi', 'a/invapi')
            --local path = path:gsub('/home/mocksoul/workspace/noc/arc/arcadia/noc', 'a/noc')
            local path = path:gsub('/home/mocksoul/workspace/noc/arc/arcadia/', 'A:')

            if path:find('^' .. 'A:noc/invapi/') ~= nil then
                path = path:gsub('A:noc/invapi/', 'INVAPI:')
            end

            if path:find('^' .. 'A:noc/') ~= nil then
                path = path:gsub('A:noc/', 'NOC:')
            end

            local path = path:gsub('([:/])internal/pkg/dep/ggt/', '%1GGT/')
            local path = path:gsub('([:/])internal/pkg/dep/', '%1DEP/')
            local path = path:gsub('([:/])internal/', '%1I/')
            local path = path:gsub('([:/])pkg/', '%1P/')

            local maxlen = 60 - 3 - 3 - 1 - 2

            if path:len() > maxlen then  -- 60 max, but also 123:321 (line:col) and padding
                local boundary = (maxlen / 2) - 1
                path = path:sub(1, boundary) .. '..' .. path:sub(-boundary)
            end

            -- local path = require('telescope.utils').path_smart(path)

            return path

            -- local tail = require('telescope.utils').path_tail(path)
            -- return string.format('%s (%s)', tail, path)
        end,
        sorting_strategy = 'ascending',
        layout_strategy = 'flex',
        layout_config = {
            horizontal = {
                --height = 0.75,
                height = function(self, max_columns, max_lines)
                    local h = max_lines * 0.95
                    if h > 75 then
                        h = 75
                    end
                    return math.floor(h)
                end,
                width = function(self, max_columns, max_lines)
                    local w = max_columns * 0.8
                    if w > 240 then
                        w = 240
                    end
                    return math.floor(w)
                end,
                mirror = false,
                prompt_position = 'bottom',
                -- preview_width = 120
            },
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
        },
    },
})
require('telescope').load_extension('fzf')

require('pqf').setup()

-- require('nice-reference').setup({
--     anchor = 'NW',
--     relative = 'cursor',
--     row = 1,
--     col = 0,
--     border = 'rounded',
--     winblend = 0,
--     max_width = 120,
--     max_height = 50,
--     auto_choose = false,
-- })

-- require('bqf').setup()
-- require('diaglist').init()

-- require('qf_helper').setup({
--     prefer_loclist = true,
--     sort_lsp_diagnostics = true,
--     quickfix = {
--         autoclose = true,
--         default_bindings = true,
--         default_options = true,
--         max_height = 20,
--         min_height = 10,
--         track_location = 'cursor',
--     },
--     loclist = {
--         autoclose = true,
--         default_bindings = true,
--         default_options = true,
--         max_height = 20,
--         min_height = 10,
--         track_location = 'cursor',
--     },
-- })

--cmp.event:on('confirm_done', autopairs.on_confirm_done)

