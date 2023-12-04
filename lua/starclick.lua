local starclick = {}

local starwindow = require('starwindow')
local starcolor = require('starcolor')

local default_click_hl = 'TermCursor'

starclick.area = function (pos, size, action, click_hl)
	return {
		pos = pos,
		size = size,
		action = action,
		click_hl = click_hl or default_click_hl,
	}
end

local function area_span(area)
	return {
		x = area.pos.x,
		area = area,
	}
end

local function empty_area_span(area)
	return {
		x = area.pos.x + area.size.x,
		area = nil,
	}
end

local function start_area_span()
	return {
		x = 0,
		area = nil,
	}
end

local function order_area_by_x(area_a, area_b)
	return area_a.pos.x < area_b.pos.x
end

local function create_area_span_map(areas, width, height)
	local lines = {}
	for i = 1, height do
		lines[i] = {}
	end
	table.sort(areas, order_area_by_x)

	local last_empty_span = start_area_span()
	for _, area in ipairs(areas) do
		local span = area_span(area)
		local empty_span = empty_area_span(area)
		local start_y = area.pos.y
		local end_y = math.min(area.pos.y + area.size.y, height)
		for y = start_y, end_y do
			if last_empty_span.x > span.x then
				table.insert(lines[y], last_empty_span)
			end
			table.insert(lines[y], span)
		end
		last_empty_span = empty_span
	end

	return lines
end

local function get_clicked_area_span(area_span_map, pos)
	local area_span_line = area_span_map[pos.y]
	if area_span_line == nil then
		return nil
	end

	local li = 1
	local ri = #area_span_line
	while li <= ri do
		local mi = math.floor((li + ri) / 2)
		local span = area_span_line[mi]
		local next_span = area_span_line[mi + 1]
		if next_span.x <= pos.x then
			li = mi + 1
		elseif span.x > pos.x then
			ri = mi - 1
		else
			return span
		end
	end

	return nil
end

local function show_click_feedback(ui, area)
	for y = area.pos.y, area.pos.y + area.size.y do
		starcolor.color_frag(nil, area.click_hl, ui.buffer, y, area.pos.x, area.size.x)
	end
end

local function click_action_callback_factory(area_span_map)
	return function ()
		local curpos_tuple = vim.fn.getcursorcharpos()
		local pos = { x = curpos_tuple[5], y = curpos_tuple[2] }
		local span = get_clicked_area_span(area_span_map, pos)
		if span ~= nil then
			if span.area ~= nil then
				show_click_feedback(span.area)
				span.area.action()
			end
		end
	end
end

starclick.attach_to_ui = function (ui, size, areas)
	local span_map = create_area_span_map(areas, size.x, size.y)
	starwindow.set_key_ui(ui, 'n', '<LeftMouse>', click_action_callback_factory(span_map))

	return {
		ui = ui,
		areas = areas,
	}
end

return starclick
