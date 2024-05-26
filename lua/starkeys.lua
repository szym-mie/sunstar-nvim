local starkeys = {}
starkeys.keytree = {}
starkeys.last_streak = nil

local starcmd = require("starcmd")
local starwindow = require('starwindow')
local starutil = require('starutil')
local starvcs = require('starvcs')
local starplugin = require('starplugin')
local starproject = require('starproject')


local function starkey_key(keystreak)
	return '<Space>'..keystreak
end

local function set_starkey(mode, keystreak, fn, opts)
	local key = starkey_key(keystreak)
	pcall(vim.keymap.del, mode, key)
	vim.keymap.set(mode, key, '', { callback = fn })
end

local alt_keychars = {
	[' '] = 'space',
	['['] = ' [ ',
	[']'] = ' ] ',
}

local function wrap_alt_keychar(char)
	return alt_keychars[char] or char
end

local function get_streak_string(path, sep)
	local string = ''
	for i = 1, #path do
		local char = string.sub(path, i, i)
		if i == 1 then
			string = wrap_alt_keychar(char)
		else
			string = string..sep..wrap_alt_keychar(char)
		end
	end
	return string
end


local function get_item_name(item_name)
	if type(item_name) == 'string' then
		return item_name
	elseif type(item_name) == 'function' then
		return item_name()
	else
		return ''
	end
end

local function sort_item_group(item_a, item_b)
		if item_a.is_group and not item_b.is_group then
			return true
		end
		if item_b.is_group and not item_a.is_group then
			return false
		end
		local item_a_key_lower = string.lower(item_a.key)
		local item_b_key_lower = string.lower(item_b.key)
		if item_a_key_lower == item_b_key_lower then
			return item_a.key > item_b.key
		else
			return item_a_key_lower < item_b_key_lower
		end

end

local function get_group_items(group)
	local keys = {}
	local entries = {}
	for key, item in pairs(group) do
		local is_group = item.group_name ~= nil
		table.insert(keys, { key = key, is_group = is_group })
	end
	table.sort(keys, sort_item_group)

	for _, key in ipairs(keys) do
		local entry = nil
		local item = group[key.key]
		if item.group_name ~= nil then
			entry = '['..get_streak_string(key.key, '-')..'] +'..get_item_name(item.group_name)
		elseif item.cmd_name ~= nil then
			entry = '['..get_streak_string(key.key, '-')..'] '..get_item_name(item.cmd_name)
		end
		table.insert(entries, entry)

	end

	return entries
end

local function find_path(group, path)
	local key = string.sub(path, 1, 1)
	local new_path = string.sub(path, 2, #path)

	if #new_path == 0 then
		return group[key]
	end
	if group[key] ~= nil and group[key].group ~= nil then
		return find_path(group[key].group, new_path)
	end
	return nil
end

local function add_group(group, new_group, path)
	local key = string.sub(path, 1, 1)
	local new_path = string.sub(path, 2, #path)

	if #new_path > 0 then
		if group[key] == nil then
			group[key] = {
				type_group = true,
				group_name = nil,
				group = {},
			}
		end
		add_group(group[key].group, new_group, new_path)
	else
		if group[key] == nil then
			group[key] = {
				type_group = true,
				group_name = new_group.group_name,
				group = {},
			}
		else
			group[key].group_name = new_group.group_name
		end
	end
end

local function add_cmd(group, new_cmd, path)
	local key = string.sub(path, 1, 1)
	local new_path = string.sub(path, 2, #path)

	if #new_path > 0 then
		if group[key] == nil then
			vim.print('starkeys: adding cmd failed: cannot complete path \''..path..'\'')
		end
		add_cmd(group[key].group, new_cmd, new_path)
	else
		group[key] = {
			type_cmd = true,
			cmd_name = new_cmd.cmd_name,
			cmd_run = new_cmd.cmd_run,
		}
	end
end

local function key_cancel_menu()
	starwindow.hide_ui(starkeys)
	starkeys.combo = nil
end

local function key_invalid_streak(path)
	starwindow.hide_ui(starkeys)
	starkeys.display_message_ui('No keystreak ['..get_streak_string(path, '-')..']')
end

local function generate_key_table(tab, start, to)
	for c = string.byte(start), string.byte(to) do
		table.insert(tab, string.char(c))
	end
end

local all_keys = {'[', ']'}
-- only number, normal and shift for now and some symbols 
generate_key_table(all_keys, '0', '9')
generate_key_table(all_keys, 'a', 'z')
generate_key_table(all_keys, 'A', 'Z')

local function set_group_empty_keys(path)
	for _, key in ipairs(all_keys) do
		local keystreak = path..key
		set_starkey('n', keystreak, function ()
			key_invalid_streak(keystreak)
		end)
	end
end

local function create_keytree(items)
	local tree = {}
	local cmds = {}
	local whens = {}

	set_group_empty_keys('')
	-- find and add groups
	for _, item in ipairs(items) do
		if item.type_group then
			set_group_empty_keys(item.group_path)
			set_starkey('n', item.group_path, function ()
	 			local group = find_path(starkeys.keytree, item.group_path)
				if group ~= nil then
					starkeys.show_ui(group.group)
				end
				starkeys.last_streak = item.group_path
			end)
			add_group(tree, item, item.group_path)
		elseif item.type_cmd then
			table.insert(cmds, item)
		elseif item.type_when then
			table.insert(whens, item)
		end
	end

	-- add commands
	for _, cmd in ipairs(cmds) do
		local cmd_fn = starcmd.cmd_callback(cmd.cmd_run, cmd.cmd_name)
		set_starkey('n', cmd.cmd_path, function ()
			cmd_fn()
			starwindow.hide_ui(starkeys)
		end, cmd.cmd_opts)
    		add_cmd(tree, cmd, cmd.cmd_path)
	end

	return tree
end

function starkeys.group (opts)
	return {
		type_group = true,
		group_path = opts.path,
		group_name = opts.name,
	}
end

function starkeys.cmd (opts)
	return {
		type_cmd = true,
		cmd_path = opts.path,
		cmd_name = opts.name,
		cmd_run = opts.run,
		cmd_opts = opts.opts,
	}
end

function starkeys.open (file)
	return function ()
		vim.cmd.tabe(file)
	end
end

function starkeys.lateinit ()
	vim.print('Lateinit - action not assigned')
end

function starkeys.with_current_path (cmd)
	return function ()
		local directory = starutil.file_directory(vim.fn.expand('%:p'))
		if directory ~= nil then
			cmd(directory)
		end
	end
end

function starkeys.todo ()
	vim.print('TODO - keystreak not functional')
end

local keys_preset = {
	starkeys.cmd { path = ',', name = 'prev tab', run = 'tabprevious', opts = { silent = true } },
	starkeys.cmd { path = '.', name = 'next tab', run = 'tabnext', opts = { silent = true } },
	starkeys.cmd { path = '1', name = 'to tab 1', run = '1tabn', opts = { silent = true } },
	starkeys.cmd { path = '2', name = 'to tab 2', run = '2tabn', opts = { silent = true } },
	starkeys.cmd { path = '3', name = 'to tab 3', run = '3tabn', opts = { silent = true } },
	starkeys.cmd { path = '4', name = 'to tab 4', run = '4tabn', opts = { silent = true } },
	starkeys.cmd { path = '5', name = 'to tab 5', run = '5tabn', opts = { silent = true } },
	starkeys.cmd { path = '6', name = 'to tab 6', run = '6tabn', opts = { silent = true } },
	starkeys.cmd { path = '7', name = 'to tab 7', run = '7tabn', opts = { silent = true } },
	starkeys.cmd { path = '8', name = 'to tab 8', run = '8tabn', opts = { silent = true } },
	starkeys.cmd { path = '9', name = 'to tab 9', run = '9tabn', opts = { silent = true } },
	starkeys.cmd { path = 's', name = 'save this file', run = ':w' },
	starkeys.cmd { path = 'S', name = 'save all', run = ':wa' },
	starkeys.cmd { path = 'U', name = 'check updates', run = starplugin.run_update },
	starkeys.cmd { path = 'o', name = 'open a file', run = function ()
		local filename = vim.fn.input('filename: ', '', 'file')
		vim.print('')
		if filename == '' then
			return
		end
		vim.cmd.tabe(filename)
	end },

	starkeys.group { path = 't', name = 'Tabs' },
	starkeys.cmd { path = 'tc', name = 'save and close this tab', run = ':wq' },
	starkeys.cmd { path = 'tD', name = 'discard and close this tab', run = ':q!' },

	starkeys.group { path = 'q', name = 'Quit' },
	starkeys.cmd { path = 'qq', name = 'save all and exit', run = ':wqa' },
	starkeys.cmd { path = 'qw', name = 'quit window', run = ':q' },
	starkeys.cmd { path = 'qD', name = 'discard and exit', run = ':qa!' },

	starkeys.group { path = 'f', name = 'Files' },
	starkeys.cmd { path = 'fd', name = 'explore current dir', run = starkeys.with_current_path(vim.cmd.tabe) },

	starkeys.group { path = 'fe', name = 'Editor' },
	starkeys.cmd { path = 'fed', name = 'open directory', run = starkeys.open(vim.fn.stdpath('config')) },
	starkeys.cmd { path = 'fel', name = 'open lua directory', run = starkeys.open(vim.fn.stdpath('config')..'/lua') },
	starkeys.cmd { path = 'fei', name = 'open init.lua', run = starkeys.open(vim.fn.stdpath('config')..'/init.lua') },
	starkeys.cmd { path = 'fea', name = 'open addon list', run = starkeys.open(vim.fn.stdpath('config')..'/plugins.txt') },
	starkeys.cmd { path = 'fec', name = 'open config', run = starkeys.open(vim.fn.stdpath('config')..'/config.txt') },

	starkeys.group { path = 'v', name = 'VCS' },

	starkeys.group { path = 'vS', name = 'Switch VCS' },
	starkeys.cmd { path = 'vSg', name = starvcs.switch_vcs_item_name('git'), run = starvcs.switch_vcs_cmd('git') },
	starkeys.cmd { path = 'vSs', name = starvcs.switch_vcs_item_name('svn'), run = starvcs.switch_vcs_cmd('svn') },
	starkeys.cmd { path = 'vSh', name = starvcs.switch_vcs_item_name('hg'), run = starvcs.switch_vcs_cmd('hg') },
	starkeys.cmd { path = 'vv', name = 'add, commit, push', run = starvcs.fast_commit },
	starkeys.cmd { path = 'vc', name = 'commit', run = starvcs.commit_window_cmd },
	starkeys.cmd { path = 'vl', name = 'log', run = starvcs.log_window_cmd },
	starkeys.cmd { path = 'vs', name = 'status', run = starvcs.status_window_cmd },
	starkeys.cmd { path = 'vp', name = 'push -> remote', run = starvcs.update_remote },
	starkeys.cmd { path = 'vP', name = 'pull <- remote', run = starvcs.update_local },
	starkeys.cmd { path = 'vr', name = 'reset', run = starvcs.reset },
	starkeys.cmd { path = 'vb', name = 'branch', run = starvcs.switch_branch_cmd },
	starkeys.cmd { path = 'vt', name = 'stash', run = starkeys.lateinit },
	starkeys.cmd { path = 'vT', name = 'retrieve stash', run = starkeys.lateinit },

	starkeys.group { path = 'p', name = 'Project' },
	starkeys.cmd { path = 'po', name = 'open project', run = starkeys.with_current_path(starproject.open_project) },
	starkeys.cmd { path = 'pc', name = 'create project', run = starkeys.with_current_path(starproject.create_project) },
	starkeys.cmd { path = 'ps', name = 'save project', run = starkeys.with_current_path(starproject.save_project) },

	starkeys.cmd { path = 'n', name = 'clear highlight', run = ':noh' }
}

function starkeys.get_ui_height (entries)
	local height = math.ceil(#entries / starkeys.ui_conf.columns)
	if height == 0 then
		return 1
	end
	return height
end

function starkeys.update_ui_wait ()
	local parent_size = starwindow.get_screen_size()
	local border = starkeys.ui_conf.border
	starkeys.ui = starwindow.set_pane_ui(starkeys.ui, 1, parent_size, border, 300)
	starwindow.update_text_buffer(starkeys.ui.buffer, { ' Please wait ' }, false)
end

function starkeys.update_ui_items (entries)
	local parent_size = starwindow.get_screen_size()
	local columns = starkeys.ui_conf.columns
	local width_pad = starkeys.ui_conf.width_pad
	local height = starkeys.get_ui_height(entries)
	local border = starkeys.ui_conf.border
	local inner_width = parent_size.x - 2
	starkeys.ui = starwindow.set_pane_ui(starkeys.ui, height, parent_size, border, 300)
	starwindow.update_menu_buffer(starkeys.ui.buffer, inner_width, width_pad, height, columns, entries)
end

function starkeys.display_message_ui (message, timeout)
	local parent_size = starwindow.get_screen_size()
	local border = starkeys.ui_conf.border
	starkeys.ui = starwindow.set_pane_ui(starkeys.ui, 1, parent_size, border, 300)
	starwindow.update_text_buffer(starkeys.ui.buffer, message, true)
	if timeout ~= nil then
		starkeys.ui.timeout_timer = vim.defer_fn(function ()
			starwindow.hide_ui(starkeys)
		end, timeout)
	end
end

function starkeys.show_ui (group)
	starkeys.update_ui_wait()
	starkeys.update_ui_items(get_group_items(group))
end

function starkeys.setup (opts)
	if opts.keys == nil then
		starkeys.keylist = keys_preset
	elseif opts.add_preset then
		starkeys.keylist = keys_preset
	for _, v in ipairs(opts.keys) do
			table.insert(starkeys.keylist, v)
		end
	else
		starkeys.keylist = opts.keys
	end

	starkeys.keytree = create_keytree(starkeys.keylist)
	vim.keymap.set('n', '<space>', function ()
		starkeys.show_ui(starkeys.keytree)
	end)

	vim.on_key(starwindow.hide_ui_callback(starkeys))

	starkeys.ui = nil
	starkeys.ui_conf = {}
	starkeys.ui_conf.height = opts.height or 4
	starkeys.ui_conf.width_pad = opts.width_pad or 8
	starkeys.ui_conf.columns = opts.columns or 4
	starkeys.ui_conf.border = opts.border or 'rounded'
end

function starkeys.add_keys (keys)
	for _, v in ipairs(keys) do
		table.insert(starkeys.keylist, v)
	end
	starkeys.keytree = create_keytree(starkeys.keylist)
end

return starkeys
