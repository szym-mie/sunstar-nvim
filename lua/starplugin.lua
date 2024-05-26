local starplugin = {
	plugins = {},
	plugin_count = 0,
	update_count = 0,
	missing_count = 0,
	plugins_checked = 0,
}

local starutil = require('starutil')
local starpopup = require('starpopup')

function starplugin.update_plugins ()
	vim.g.plug_window = ''
	vim.cmd([[tabe]])
	vim.cmd([[PlugUpdate]])
end

local function get_plugin_item (dir)
	return {
		dir = dir,
		done = false,
		is_missing = false,
		has_updates = false,
	}
end

local function get_check_complete_popup_text (missing_count, update_count)
	local text = ''
	if missing_count > 0 then
		text = text..missing_count..' plugin/s missing'
	end
	if update_count > 0 then
		local sep = missing_count > 0 and ' + ' or ''
		text = text..sep..update_count..' update/s available'
	end
	return text..'. Do you want to update now?'
end

local function on_check_complete ()
	if starplugin.missing_count > 0 or starplugin.update_count > 0 then
		local level = starplugin.missing_count > 0 and 'warn' or 'info'
		starpopup.popup(
			'StarPlugin',
			level,
			get_check_complete_popup_text(starplugin.missing_count, starplugin.update_count),
			{
				starpopup.action { key = '<Enter>', text = 'update', run = starplugin.update_plugins },
				starpopup.action_dismiss('q'),
			},
			2)
	end
end

local function check_for_update_job_fn (plugin_id)
	return function (_, data, _)
		local plugin = starplugin.plugins[plugin_id]
		plugin.done = true

		-- detect missing plugins too.
		local commits_behind_count = tonumber(data[1])
		local is_missing = commits_behind_count == nil
		local has_updates = (commits_behind_count or 0) > 0
		if is_missing then
			plugin.is_missing = true
			starplugin.missing_count = starplugin.missing_count + 1
		end
		if has_updates then
			plugin.has_updates = true
			starplugin.update_count = starplugin.update_count + 1
		end

		starplugin.plugins_checked = starplugin.plugins_checked + 1
		if starplugin.plugins_checked == starplugin.plugin_count then
			on_check_complete()
		end
	end
end

local function check_for_update (plugin_id)
	local plugin = starplugin.plugins[plugin_id]
	local dir = plugin.dir

	local count_job_opts = {
		on_stdout = check_for_update_job_fn(plugin_id),
		stdout_buffered = true,
	}
	local count_cmd = 'git -C '..dir..' rev-list HEAD..origin --count'

	local fetch_job_opts = {
		on_exit = function (_, _, _)
			vim.fn.jobstart(count_cmd, count_job_opts)
		end
	}
	local fetch_cmd = 'git -C '..dir..' fetch'

	vim.fn.jobstart(fetch_cmd, fetch_job_opts)
end

function starplugin.run_update ()
	for plugin_id, plugin_info in pairs(vim.g.plugs) do
		local dir = plugin_info.dir
		starplugin.plugins[plugin_id] = get_plugin_item(dir)
		starplugin.plugin_count = starplugin.plugin_count + 1
	end

	for plugin_id in pairs(starplugin.plugins) do
		check_for_update(plugin_id)
	end
end

function starplugin.get_plug_vim_path ()
	local data_dir = vim.fn.stdpath('data')..'/site'
	return data_dir..'/autoload/plug.vim'
end

function starplugin.is_installed ()
	return vim.fn.filereadable(starplugin.get_plug_vim_path()) == 1
end

function starplugin.try_install ()
	local plug_dir = starplugin.get_plug_vim_path()
	local has_plugvim = vim.fn.filereadable(plug_dir)
	if has_plugvim == 0 then
		vim.print('Installing plugin manager now.')
		local has_curl = vim.fn.executable('curl')
		local url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
		local curl_cmd = 'curl --insecure -fLo '..plug_dir..' --create-dirs '..url
		local curl_job_id = vim.fn.jobstart(curl_cmd, vim.empty_dict())
		local curl_exit = vim.fn.jobwait({curl_job_id})[1]
		if curl_exit ~= 0 then
			if has_curl == 1 then
				vim.print('[Error] curl failed with code: '..curl_exit)
			else
				vim.print('[Error] curl not found: install curl or install vim-plug manually')
			end
		end
		return false
	end
	return true
end

function starplugin.get_addons (plugin_load, filepath)
	for _, plugin_id in ipairs(starutil.read_flat_config(filepath)) do
		if #plugin_id > 0 then
			plugin_load(plugin_id)
		end
	end
end

return starplugin
