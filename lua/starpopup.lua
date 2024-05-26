local starpopup = {
	main_space = nil
}

local starwindow = require('starwindow')
local starstyle = require('starstyle')

local expand_dir_enum = {
	NW = { x =  1, y =  1 },
	SW = { x =  1, y = -1 },
	NE = { x = -1, y =  1 },
	SE = { x = -1, y = -1 },
}

function starpopup.get_popup_pos (popup_space, n)
	-- because indexing from 1 in lua
	local i = n - 1
	local pos = {
		x = popup_space.init_pos.x,
		y = popup_space.init_pos.y,
	}
	pos.x = pos.x + i * popup_space.step_size.x
	-- TODO allow for horizontal growth
	-- pos.y = pos.y + i * popup_space.step_size.y
	if starpopup.check_clipping(popup_space, pos) then
		return pos
	end
end

function starpopup.check_clipping (popup_space, pos)
	-- TODO add boundary check and a overflow message
	return true
end

function starpopup.create_popup_space (init_pos, popup_size, actions_sep_char, anchor)
	local step_x = expand_dir_enum[anchor].x * (popup_size.x + 1)
	local step_y = expand_dir_enum[anchor].y * (popup_size.y + 1)

	return {
		init_pos = init_pos,
		popup_size = popup_size,
		actions_sep_char = actions_sep_char,
		anchor = anchor,
		step_size = { x = step_x, y = step_y },
		popups = {},
	}
end

function starpopup.remove_from_popup_space (popup)
	local popup_space = popup.space
	local is_found = false
	for i, popup_item in ipairs(popup_space.popups) do
		if is_found then
			local new_pos = starpopup.get_popup_pos(popup_space, i - 1)
			starpopup.move_popup(popup_item, new_pos)
		end

		if popup_item == popup and not is_found then
			table.remove(popup_space.popups, i)
			is_found = true
		end
	end
end

local popup_level_enum = {
	info = '(i)',
	warn = '/!\\',
	error = '[!]',
}

local popup_hl_spec_enum = {
	info = { fg = '#dbebfc', bg = '#0079b2' },
	warn = { fg = '#fcd4d4', bg = '#db9615' },
	error = { fg = '#fcd4d4', bg = '#a81717' },
}

local popup_color_group = starstyle.style_group('popup_hl', popup_hl_spec_enum)

local function popup_on_exit_factory(popup)
	return function ()
		starpopup.close_popup(popup)
	end
end

function starpopup.create_popup (popup_space, title, level, text, actions, actions_per_row, timeout)
	local next_pos = starpopup.get_popup_pos(popup_space, #popup_space.popups + 1)
	local popup_size = popup_space.popup_size
	local anchor = popup_space.anchor
	local ui = starwindow.create_ui(next_pos, popup_size, 'rounded', anchor)
	starwindow.set_title(ui, title)
	local popup = {
		title = title,
		level = level,
		text = text,
		actions = actions,
		actions_per_row = actions_per_row,
		actions_sep_char = popup_space.actions_sep_char,
		timeout = timeout,
		space = popup_space,
		pos = next_pos,
		size = popup_size,
		ui = ui,
	}

	starpopup.update_popup_buffer(popup)
	-- TODO actions do actions? (mouse clicks)
	starwindow.set_actions_keymaps(popup.actions, popup.ui, popup_on_exit_factory(popup))
	-- TODO add timeout

	return popup
end

function starpopup.move_popup (popup, new_pos)
	starwindow.resize_ui(popup.ui, new_pos, popup.size, popup.anchor)
	popup.pos = new_pos
end

function starpopup.update_popup_buffer (popup)
	-- TODO try adding small text-graphics to indicate type of msg
	local width = popup.size.x
	local height = popup.size.y

	local text_lines = starwindow.text_break(popup.text, width, 2)
	local action_maps = starwindow.get_actions_maps(popup.actions, width, popup.actions_per_row, popup.actions_sep_char)
	local action_lines = action_maps.lines

	local text_height = height - #action_lines - 2

	local lines = {}

	-- banner line
	local level_icon_pad = 0
	local level_icon = popup_level_enum[popup.level]
	local level_icon_before = string.rep(' ', level_icon_pad)
	local level_icon_after = string.rep(' ', width - #level_icon_before - #level_icon)
	table.insert(lines, level_icon_before..level_icon..level_icon_after)
	-- text
	for i = 1, text_height do
		table.insert(lines, text_lines[i] or '')
	end
	table.insert(lines, '')
	-- actions
	for _, line in ipairs(action_lines) do
		table.insert(lines, line)
	end

	starwindow.update_text_buffer(popup.ui.buffer, lines)
	starstyle.color_frag(popup_color_group, popup.level, popup.ui.buffer, 0, level_icon_pad, 3)
end

function starpopup.close_popup (popup)
	starwindow.close_ui(popup.ui)
	starpopup.remove_from_popup_space(popup)
end

function starpopup.setup (opts)
	local init_pos = opts.init_pos or { x = 1, y = 3 }
	local popup_size = opts.popup_size or { x = 40, y = 5 }
	local actions_sep_char = opts.actions_sep_char or '|'
	local anchor = opts.anchor or 'SE'

	starpopup.main_space = starpopup.create_popup_space(init_pos, popup_size, actions_sep_char, anchor)
end

function starpopup.popup (title, level, text, actions, actions_per_row, timeout, custom_popup_space)
	local popup_space = custom_popup_space or starpopup.main_space
	local popup = starpopup.create_popup(popup_space, title, level, text, actions, actions_per_row, timeout)
	table.insert(popup_space.popups, popup)
end

function starpopup.action (opts)
	return {
		key = opts.key,
		text = opts.text,
		run = opts.run,
	}
end

function starpopup.action_dismiss (key)
	return {
		key = key,
		text = 'dismiss',
		run = function () end,
	}
end

return starpopup
