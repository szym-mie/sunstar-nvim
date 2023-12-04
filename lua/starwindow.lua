local starwindow = {}

local starcmd = require('starcmd')

starwindow.get_screen_size = function ()
	return {
		x = vim.o.columns,
		y = vim.o.lines,
	}
end

local pos_anchor_enum = {
	NW = { x = 0, y = 0 },
	NE = { x = 1, y = 0 },
	SW = { x = 0, y = 1 },
	SE = { x = 1, y = 1 },
}

starwindow.resolve_pos = function (pos, anchor)
	if anchor == nil then
		return pos
	end

	local parent_size = starwindow.get_screen_size()
	local reverse = pos_anchor_enum[anchor]
	local new_x = math.abs(reverse.x * parent_size.x - pos.x)
	local new_y = math.abs(reverse.y * parent_size.y - pos.y)

	return { x = new_x, y = new_y }
end

starwindow.replace_with_string = function(s, ns, p, l)
	return string.sub(s, 1, p-1) .. string.sub(ns, 1, l) .. string.sub(s, p+l)
end

starwindow.set_title = function (ui, title)
	vim.api.nvim_win_set_config(ui.window, { title = ' '..title..' ', title_pos = 'center' })
end

starwindow.update_menu_buffer = function(buffer, width, width_pad, height, columns, entries)
	local rows = {}
	for i = 1, height do
		rows[i] = string.rep(' ', width)
	end

	local content_width = width - width_pad * 2
	local entry_width = math.floor(content_width / columns)

	for i, entry in ipairs(entries) do
		local j = i - 1
		local row = math.floor(j / columns)
		local column = j - row * columns

		local entry_start = width_pad + entry_width * column
		local entry_length = math.min(#entry, entry_width - 1)
		rows[row+1] = starwindow.replace_with_string(rows[row+1], entry, entry_start, entry_length)
	end

	vim.api.nvim_buf_set_lines(buffer, 0, -1, true, rows)
end

starwindow.update_text_buffer = function (buffer, text, break_lines)
	if type(text) == 'string' then
		local lines = {}
		if break_lines == true then
			for line in string.gmatch(text, '([^\\n]+)') do
				table.insert(lines, line)
			end
		else
			lines = {string.gsub(text, '\\n', '')}
		end
		vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)
	elseif type(text) == 'table' then
		vim.api.nvim_buf_set_lines(buffer, 0, -1, true, text)
	end
end

starwindow.create_ui = function (window_pos, window_size, border, anchor, zindex)
	local buffer = vim.api.nvim_create_buf(false, true)
	local real_pos = starwindow.resolve_pos(window_pos, anchor)
	local window_config = {
		relative = 'editor',
		anchor = anchor,
		col = real_pos.x,
		row = real_pos.y,
		width = window_size.x,
		height = window_size.y,
		style = 'minimal',
		zindex = zindex or 50,
		border = border or 'none',
	}

	return {
		buffer = buffer,
		window = vim.api.nvim_open_win(buffer, false, window_config),
		window_pos = real_pos,
		window_size = window_size,
	}
end

starwindow.resize_ui = function (ui, window_pos, window_size, anchor)
	local real_pos = starwindow.resolve_pos(window_pos, anchor)
	local window_config = {
		relative = 'win',
		anchor = anchor,
		col = real_pos.x,
		row = real_pos.y,
		width = window_size.x,
		height = window_size.y,
	}
	vim.api.nvim_win_set_config(ui.window, window_config)
	ui.window_pos = real_pos
	ui.window_size = window_size
end

starwindow.set_ui = function (ui, window_pos, window_size, border, anchor, zindex)
	if ui == nil or not vim.api.nvim_win_is_valid(ui.window) then
		ui = starwindow.create_ui(window_pos, window_size, border, anchor, zindex)
	else
		starwindow.resize_ui(ui, window_pos, window_size, anchor)
	end
	return ui
end

starwindow.set_pane_ui = function (ui, window_height, parent_size, border, zindex)
	local window_pos = { x = 0, y = parent_size.y - window_height }
	local window_size = { x = parent_size.x, y = window_height }
	return starwindow.set_ui(ui, window_pos, window_size, border, nil, zindex)
end

starwindow.set_key_ui = function (ui, mode, key, fn)
	pcall(vim.api.nvim_buf_del_keymap, ui.buffer, mode, key)
	vim.api.nvim_buf_set_keymap(ui.buffer, mode, key, '', { callback = fn })
end

starwindow.set_on_event = function (ui, events, on_event_fn)
	vim.api.nvim_create_autocmd(events, {
		buffer = ui.buffer,
		callback = on_event_fn,
	})
end

starwindow.focus_ui = function (ui)
	vim.api.nvim_set_current_win(ui.window)
end

starwindow.close_ui = function (ui)
	vim.api.nvim_win_close(ui.window, true)
	vim.api.nvim_buf_delete(ui.buffer, { force = true })
end

starwindow.hide_ui = function (obj)
	if obj.ui ~= nil then
		starwindow.close_ui(obj.ui)
		obj.ui = nil
	end
end

starwindow.hide_ui_callback = function (obj)
	return function (_)
		starwindow.hide_ui(obj)
	end
end

starwindow.text_break = function (text, width, pad_width)
	if pad_width == nil then
		pad_width = 0
	end

	local lines = {}
	local pad = string.rep(' ', pad_width)
	local line_width = width - 2 * pad_width
	local buffer = ''
	for line in string.gmatch(text, '([^\n\r]+)') do
		for frag in string.gmatch(line, '([^ ]+ *)') do
			local word = string.match(frag, '([^ ]+)')
			if #buffer + #frag <= line_width then
				buffer = buffer..frag
			elseif #buffer + #word <= line_width then
				buffer = buffer..word
			else
				table.insert(lines, pad..buffer)
				buffer = frag
			end
		end
		-- insert an explicit newline
		if #buffer > 0 or #line == 0 then
			table.insert(lines, pad..buffer)
			buffer = ''
		end
	end
	if #buffer > 0 then
		table.insert(lines, pad..buffer)
	end

	return lines
end

starwindow.trim_string_to_len = function (str, max_len, more_str)
	if #str > max_len then
		return string.sub(1, max_len - #more_str)..more_str
	end
	return str
end

starwindow.trim_pad_string_to_len = function (str, len, more_str, pad_char)
	if #str > len then
		return string.sub(str, 1, len - #more_str)..more_str
	end
	local spare_width = len - #str
	local odd_width_rest = spare_width % 2
	local pad_width = math.floor(spare_width / 2)

	return string.rep(pad_char, pad_width)..str..string.rep(pad_char, pad_width + odd_width_rest)
end

starwindow.join_string_lines = function (lines)
	local str = ''
	for _, line in ipairs(lines) do
		str = str..line..'\n'
	end
	return str
end

starwindow.join_action_items = function (items, item_width, sep_char)
	local buf = ''
	for i, item in ipairs(items) do
		-- include one-space padding
		local str = ' '..starwindow.trim_pad_string_to_len(item, item_width - 2, '...', ' ')..' '
		if i == 1 then
			buf = str
		else
			buf = buf..sep_char..str
		end
	end

	return buf
end

starwindow.get_actions_maps = function (actions, width, actions_per_row, actions_sep_char)
	-- TODO add areas for mouse clicking
	-- with accounting of separator chars
	local final_width = width - actions_per_row
	local item_width = math.floor(final_width / actions_per_row)
	local action_items = {}

	for _, action in ipairs(actions) do
		table.insert(action_items, '['..action.key..'] '..action.text)
	end

	local lines = {}
	local line_items = {}
	for _, action_item in ipairs(action_items) do
		table.insert(line_items, action_item)
		if #line_items >= actions_per_row then
			local line = starwindow.join_action_items(line_items, item_width, actions_sep_char)
			table.insert(lines, line)
			line_items = {}
		end
	end

	return {
		lines = lines,
		areas = {},
	}
end

starwindow.set_actions_keymaps = function (actions, ui, on_exit_fn)
	for _, action in ipairs(actions) do
		local cmd_fn = starcmd.cmd_callback(action.run, action.text)
		starwindow.set_key_ui(ui, 'n', action.key, function ()
			cmd_fn()
			on_exit_fn()
		end)
	end
end

return starwindow
