local starplugin = require('starplugin')


vim.print('--- Messages start ---')
-- plugin manager install
local install_success = false
if not starplugin.try_install() then
	vim.print('--- Installation summary ---')
	vim.cmd.sleep(2)
	local config_dir = vim.fn.stdpath('config')
	local after_install_path = config_dir..'/AFTER_INSTALL.txt'
	local init_path = config_dir..'/init.lua'
	vim.cmd.tabe(init_path)
	vim.cmd.tabe(after_install_path)
	if (starplugin.is_installed()) then
		vim.print('[OK] plug-vim: installation success')
		install_success = true
	else
		vim.print('[Error] plug-vim: NOT FOUND - CHECK INSTALLATION')
	end
	vim.cmd.mes()
	if not install_success then
		return
	else
		vim.cmd.source(starplugin.get_plug_vim_path())
	end
end


-- plugin loading
vim.call('plug#begin')
local Plug = vim.fn['plug#']

-- lsp
Plug 'neovim/nvim-lspconfig'

-- completion
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/cmp-vsnip'

-- file explorer + icons
Plug 'stevearc/oil.nvim'
Plug 'nvim-tree/nvim-web-devicons'

-- smooth scroll
Plug 'karb94/neoscroll.nvim'

starplugin.get_addons(Plug)

vim.call('plug#end')

-- after plug installed run plugin update
if install_success then
	starplugin.update_plugins()
end


-- load the config - set theme etc.
local starstore = require('starstore')
starstore.setup({})

local main_config = starstore.new({
	filepath = starstore.in_config_path('config.txt'),
	apply_callbacks = {
		['theme'] = vim.cmd.colorscheme,
	}
})

local starpopup = require('starpopup')
starpopup.setup({})

local starkeys = require('starkeys')
starkeys.setup({})

local starvcs = require('starvcs')
starvcs.setup({})

-- update plugins after init popups
starplugin.run_update()


-- keys
local config_keys = {
	starkeys.group { path = 'fc', name = 'Config' },
	starkeys.cmd { path = 'fcr', name = 'reload', run = function ()
		starstore.reload(main_config)
	end },
	starkeys.cmd { path = 'T', name = 'theme', run = function ()
		local theme = vim.fn.input('theme: ', '', 'color')
		starstore.set(main_config, starstore.qname_of('theme'), theme, true)
	end },
}

starkeys.add_keys(config_keys)


-- completion
local cmp = require('cmp')
cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn['vsnip#anonymous'](args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		{ name = 'vsnip' },
	}, {
		{ name = 'buffer' },
	})
})

cmp.setup.filetype('gitcommit', {
	sources = cmp.config.sources({
		{ name = 'git' },
	}, {
		{ name = 'buffer' },
	})
})


-- lsp
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspconfig = require('lspconfig')
local servers = {'zls', 'clojure_lsp', 'clangd', 'hls'}
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup {
		capabilities = capabilities
	}
end
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function (ev)
		vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

		local opts = { buffer = ev.buf }
		local lsp_keys = {
			starkeys.cmd { path = ' ', name = 'hover', run = vim.lsp.buf.hover, opts = opts },
			starkeys.group { path = 'r', name = 'Refactor' },
			starkeys.cmd { path = 'rr', name = 'rename', run = vim.lsp.buf.rename, opts = opts },
			starkeys.cmd { path = 'ra', name = 'code action', run = vim.lsp.buf.code_action, opts = opts },
			starkeys.cmd { path = 'rf', name = 'format file', run = vim.lsp.buf.format, opts = opts },
			starkeys.group { path = 'i', name = 'Introspection' },
			starkeys.cmd { path = 'id', name = 'type definition', run = vim.lsp.buf.type_definition, opts = opts },
			starkeys.cmd { path = 'ir', name = 'references', run = vim.lsp.buf.references, opts = opts },
			starkeys.cmd { path = 'i]', name = 'next error/warn', run = vim.diagnostic.goto_next, opts = opts },
			starkeys.cmd { path = 'i[', name = 'prev error/warn', run = vim.diagnostic.goto_prev, opts = opts },
		}
		starkeys.add_keys(lsp_keys)
	end
})
local lsp_border = 'rounded'
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  	vim.lsp.handlers.hover,
	{ border = lsp_border }
)
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
	vim.lsp.handlers.signature_help,
	{ border = lsp_border }
)
vim.diagnostic.config({
	float = { border = lsp_border }
})


-- vim dev
if starstore.get_bool(main_config, starstore.qname_of('vim_dev')) then
	lspconfig['lua_ls'].setup {
		capabilities = capabilities,
		settings = {
			Lua = {
				runtime = {
					version = 'LuaJIT',
				},
				diagnostics = {
					globals = { 'vim' },
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file('', true),
				},
				telemetry = {
					enable = false,
				},
			},
		},
	}
end


-- file explorer
local oil = require('oil')
oil.setup({
	columns = {
		'icon',
		'size'
	},
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
	restore_win_options = true,
	keymaps = {
		['<Backspace>'] = 'actions.parent',
		['<CR>'] = 'actions.select',
	},
})


-- enhanced scroll
local neoscroll = require('neoscroll')
neoscroll.setup()


-- core config
local core_config = require('config.core')
core_config.setup({})


-- show splash screen
if #vim.fn.expand('%:p') == 0 then
	vim.cmd(':e .')
	require('screens.splash')
end

