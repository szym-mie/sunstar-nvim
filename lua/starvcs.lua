local starvcs = {
	found = {},
	current_vcs = nil,
	ui = nil,
}

local starwindow = require('starwindow')
local starcolor = require('starcolor')
local starutil = require('starutil')
local oil = require('oil')

-- TODO display errors and outcomes to window

local function todo() end

local supported_vcs = {'git', 'svn', 'hg'}
local vcs_cmds = {
	vcs_detect = {
		git = {'status -s'},
		svn = {'info'},
		hg = {'status'},
	},
	vcs_root = {
		git = {'rev-parse --show-toplevel'},
		svn = {todo},
		hg = {'root'},
	},
	init = {
		git = {'init', 'remote add origin $remote_url'},
		svn = {'checkout $remote_url'},
		hg = {todo},
	},
	clone = {
		git = {'clone $url'},
		svn = {todo},
		hg = {todo},
	},
	add = {
		git = {'add $files'},
		svn = {'add $files --force'},
		hg = {todo},
	},
	log = {
		git = {'log'},
		svn = {'log'},
		hg = {todo},
	},
	status = {
		git = {'status -sbu'},
		svn = {'status'},
		hg = {todo},
	},
	commit = {
		git = {'commit -m $msg'}, -- TODO better way of displaying commit
		svn = {'commit'},
		hg = {todo},
	},
	update_remote = {
		git = {'push --set-upstream origin $branch'},
		svn = {}, -- no such thing in svn
		hg = {todo},
	},
	update_local = {
		git = {'pull origin'},
		svn = {'update'},
		hg = {todo},
	},
	reset = {
		git = {'reset'},
		svn = {'revert -R .'},
		hg = {todo},
	},
	switch_branch = {
		git = {'checkout $branch'},
		svn = {'switch $branch'},
		hg = {todo},
	},
	list_branches = {
		git = {'branch -avl'},
		svn = {todo},
		hg = {todo},
	},
	push_stash = {
		git = {'stash push'},
	},
	pop_stash = {
		git = {'stash pop'}
	},
}

local function apply_params(cmd, params)
	local out_cmd = cmd
	for param_name, param_val in pairs(params) do
		out_cmd = string.gsub(out_cmd, '$'..param_name, param_val)
	end
	return out_cmd
end

local function exec_cmds(cmd_name, cmd_args, params, job_opts, async)
	local jobs = {}
	local jobs_exit_codes = {}
	for i, args in ipairs(cmd_args) do
		local job_cmd = cmd_name..' '..apply_params(args, params)
		local job_id = vim.fn.jobstart(job_cmd, {
			cwd = job_opts.path,
			on_exit = function (_, exit_code, _)
				jobs_exit_codes[i] = exit_code
				vim.print('exit code '..exit_code)
			end,
			on_stdout = job_opts.on_stdout,
			on_stderr = job_opts.on_stderr,
			stdout_buffered = not job_opts.unbuffered,
			stderr_buffered = not job_opts.unbuffered,
		})
		if job_id == 0 or job_id == -1 then
			vim.print('could not start job '..i)
			return jobs_exit_codes
		end
		jobs[i] = job_id
		if not async then
			vim.fn.jobwait({job_id})
		end
	end

	if async then
		vim.fn.jobwait(jobs)
	end

	return jobs_exit_codes
end

local function get_dir_path()
	local oil_path = oil.get_current_dir()
	vim.print(oil_path)
	vim.print(vim.fn.expand('%:p:h'))
	return oil_path or vim.fn.expand('%:p:h')
end

local function vcs_exec(vcs, cmd, params, job_opts)
	if vcs == nil then
		return { error = 'no vcs available' }
	end
	local cmds_group = vcs_cmds[cmd]
	if cmds_group == nil then
		return { error = 'no cmd group \''..cmd..'\'' }
	end
	local cmds = cmds_group[vcs]
	if cmds == nil then
		return { error = 'no \''..vcs..'\' cmds for group' }
	end
	if job_opts.path == nil then
		job_opts.path = get_dir_path()
	end
	return exec_cmds(vcs, cmds, params, job_opts)
end

local function jobs_get_error(jobs_error_codes)
	for i, job_error_code in ipairs(jobs_error_codes) do
		if job_error_code ~= 0 then
			return i
		end
	end
	return nil
end

local function is_jobs_success(jobs_error_codes)
	return jobs_get_error(jobs_error_codes) == nil
end

starvcs.vcs_detect = function (vcs)
	local jobs_result = vcs_exec(vcs, 'vcs_detect', {}, {})

	return is_jobs_success(jobs_result)
end

starvcs.vcs_detect_save = function (vcs)
	local is_found = starvcs.vcs_detect(vcs)
	if is_found then
		starvcs.current_vcs = vcs
	end
	starvcs.found[vcs] = is_found

	return is_found
end

starvcs.vcs_detect_all = function ()
	local found = {}
	for _, vcs in ipairs(supported_vcs) do
		found[vcs] = starvcs.vcs_detect(vcs)
	end

	return found
end

starvcs.vcs_detect_save_all = function ()
	local found = {}
	for _, vcs in ipairs(supported_vcs) do
		found[vcs] = starvcs.vcs_detect_save(vcs)
	end

	return found
end

starvcs.vcs_root = function (vcs, path, on_result)
	local job_opts = {
		path = path,
		on_stdout = function (_, data, _)
			local npath = starutil.get_path_normal_form(data[1])
			on_result(npath)
		end,
	}
	local jobs_result = vcs_exec(vcs, 'vcs_root', {}, job_opts)

	return is_jobs_success(jobs_result)
end

starvcs.get_current_vcs = function ()
	if starvcs.current_vcs == nil then
		vim.print(starvcs.vcs_detect_save_all())
	end

	return starvcs.current_vcs
end

starvcs.init = function (vcs, remote_url, on_out, on_err)
	local params = { remote_url = remote_url }
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'init', params, job_opts)

	if is_jobs_success(jobs_result) then
		starvcs.current_vcs = vcs
	end
end

starvcs.add = function (files, on_out, on_err)
	if files == nil then
		files = '.'
	end
	local vcs = starvcs.get_current_vcs()
	local params = { files = files }
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'add', params, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.log = function (on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'log', {}, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end

	return jobs_result
end

starvcs.status = function (on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'status', {}, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.commit = function (msg, on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local params = { msg = msg }
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'commit', params, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.update_remote = function (branch, on_out, on_err)
	if branch == nil then
		branch = ''
	end
	local vcs = starvcs.get_current_vcs()
	local params = { branch = branch }
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'update_remote', params, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.fast_commit = function (msg, on_out, on_err)
	starvcs.add(nil, on_out, on_err)
	starvcs.commit(msg, on_out, on_err)
	starvcs.update_remote(nil, on_out, on_err)
end

starvcs.update_local = function (on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'update_local', {}, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.reset = function (on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'reset', {}, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.switch_branch = function (branch, on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local params = { branch = branch }
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'switch_branch', params, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.list_branches = function (on_out, on_err)
	local vcs = starvcs.get_current_vcs()
	local params = {}
	local job_opts = {
		on_stdout = on_out,
		on_stderr = on_err,
	}
	local jobs_result = vcs_exec(vcs, 'list_branches', params, job_opts)

	if not is_jobs_success(jobs_result) then
		-- TODO report error
	end
end

starvcs.switch_vcs_item_name = function (vcs)
	return function ()
		local is_detected = starvcs.vcs_detect_save(vcs)
		local option_name = (is_detected and 'switch to ' or 'init ')..vcs
		if is_detected and vcs == starvcs.current_vcs then
			option_name = option_name..' (current)'
		end
		return option_name
	end
end

starvcs.switch_vcs_cmd = function (vcs)
	return function ()
		local is_detected = starvcs.vcs_detect_save(vcs)
		if is_detected then
			starvcs.current_vcs = vcs
		else
			local remote_url = vim.fn.input('remote url: ', '')
			starvcs.init(vcs, remote_url)
		end
	end
end

starvcs.switch_branch_cmd = function ()
	-- TOOD temporary way of switching
	starvcs.switch_branch_window()
	local branch = vim.fn.input('branch: ', '')
	starvcs.branch(branch)
end

starvcs.create_window = function (data_source, modify_data_fn, post_create_ui_fn, on_event_fn_map)
	local height = starvcs.ui_conf.rows[data_source] or starvcs.ui_conf.fallback_rows

	local function create_window_ui(data)
		local lines = {}
		local modify_line_fn = modify_data_fn or starutil.identity
		for i, line in ipairs(data) do
			lines[i] = modify_line_fn(line)
		end
		starvcs.ui = starwindow.set_pane_ui(starvcs.ui, height, starwindow.get_screen_size(), 'rounded')
		starwindow.update_text_buffer(starvcs.ui.buffer, lines, false)
		if post_create_ui_fn ~= nil then
			post_create_ui_fn(starvcs.ui, lines)
		end

		-- event_fn params 
		-- (id: autocmd id, 
		--  event: name of event, 
		--  group: autcmd group id,
		--  match: amatch for autocmd,
		--  buf: current buffer,
		--  file: current buffer file,
		--  data: possible data from nvim)
		if on_event_fn_map ~= nil then
			for events, event_fn in pairs(on_event_fn_map) do
				starwindow.set_on_event(starvcs.ui, events, event_fn)
			end
		end
		starwindow.focus_ui(starvcs.ui)
	end

	if data_source == nil then
		create_window_ui({})
	else
		if type(data_source) == 'function' then
			-- regular function
			create_window_ui(data_source())
		elseif type(data_source) == 'string' then
			-- vcs command
			local vcs_cmd = data_source
			local status = starvcs[vcs_cmd](function (_, data, _)
				create_window_ui(data)
			end, function (_, data, _)
				local err_height = #data - 1
				if err_height < 1 then
					return
				end
				local nonempty_data = { unpack(data, 1, err_height) }
				create_window_ui(nonempty_data)
			end)
		end
	end

end

starvcs.add_window_cmd = function ()
	-- TODO
end

starvcs.log_window_cmd = function ()
	starvcs.create_window('log', nil, function (ui, lines)
		for i, line in ipairs(lines) do
			if string.match(line, '^commit') then
				starcolor.color_line(nil, 'Special', ui.buffer, i - 1)
			end
		end
	end)
end

local status_highlight_colors = {
	A = 'String',
	M = 'Special',
	D = 'Exception',
}

local function status_highlight(ui, lines)
	for i, line in ipairs(lines) do
		local item_status = string.match(line, '^[^#][^#]')
		if item_status ~= nil then
			local s1 = string.sub(item_status, 1, 1)
			local s2 = string.sub(item_status, 2, 2)
			vim.print(s1)
			vim.print(s2)
			if s1 == ' ' or item_status == '??' then
				starcolor.color_frag(nil, 'Exception', ui.buffer, i - 1, 0, 2)
			elseif item_status == '!!' then
				starcolor.color_frag(nil, 'Comment', ui.buffer, i - 1, 0, 2)
			else
				local color_group = status_highlight_colors[s1]
				starcolor.color_frag(nil, color_group, ui.buffer, i - 1, 0, 2)
			end
		end
	end
end

starvcs.status_window_cmd = function ()
	starvcs.create_window('status', nil, status_highlight)
end

starvcs.commit_window_cmd = function ()
	local function on_commit_fn_factory(buffer)
		return function ()
			local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
			if string.match(lines[1], '^#') then
				lines[1] = ''
			end
			vim.print(starwindow.join_string_lines(lines))
			starvcs.commit(starwindow.join_string_lines(lines), nil, function (_, data, _) vim.print(data) end)
			vim.print('commit done')
		end
	end

	starvcs.create_window(
		function () return {'# Enter commit message, press [Enter] to commit'} end,
		nil,
		function (ui, _)
			starcolor.color_line(nil, 'Comment', ui.buffer, 0)
			starwindow.set_key_ui(ui, 'n', '<Enter>', on_commit_fn_factory(ui.buffer))
		end)
end

starvcs.switch_branch_window = function ()
	starvcs.create_window('list_branches', function (line)
		return string.gsub(line, '^%*', '-')
	end, function (ui, lines)
		for i, line in ipairs(lines) do
			if string.match(line, '^-') then
				starcolor.color_line(nil, 'String', ui.buffer, i - 1)
			end
		end
	end)
end

local default_rows = {
	add = 18,
	log = 12,
	status = 8,
	commit = 8,
	list_branches = 8,
}

starvcs.setup = function (opts)
	starvcs.ui_conf = {}
	starvcs.ui_conf.height = opts.height or 4
	starvcs.ui_conf.width_pad = opts.width_pad or 8
	starvcs.ui_conf.rows = opts.rows or default_rows
	starvcs.ui_conf.fallback_rows = 8
	starvcs.ui_conf.columns = opts.columns or 4
	starvcs.ui_conf.border = opts.border or 'rounded'
	-- vim.on_key(starwindow.hide_ui_callback(starvcs))
end

return starvcs
