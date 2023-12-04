local starcolor = {}

local function get_full_key(ns_key, key)
	return ns_key..'_'..key
end

starcolor.rgb = function (r, g, b)
	return string.format('#%02x%02x%02x', r, g, b)
end

starcolor.rgb_vec = function (vec)
	return starcolor.rgb(vec.r, vec.g, vec.b)
end

local function lerp(a, b, r)
	return a * (1 - r) + b * r
end

starcolor.lerp_vec = function (vec_a, vec_b, r)
	return {
		r = lerp(vec_a.r, vec_b.r, r),
		g = lerp(vec_a.g, vec_b.g, r),
		b = lerp(vec_a.b, vec_b.b, r),
	}
end

starcolor.gradient = function (from, to, steps)
	local colors = {}
	for i = 1, steps do
		local src_mul = (i - 1) / (steps - 1)
		local color_vec = starcolor.lerp_vec(from, to, src_mul)
		table.insert(colors, starcolor.rgb_vec(color_vec))
	end

	return colors
end

starcolor.text_color_group = function (ns_key, hl_spec_map)
	local group = {}
	for key, hl_spec in pairs(hl_spec_map) do
		local full_key = get_full_key(ns_key, key)
		group[full_key] = { is_init = false, hl_spec = hl_spec }
	end

	return {
		ns_key = ns_key,
		colors = group,
	}
end

starcolor.text_color_group_from_seqs = function (ns_key, seq_option_map)
	local hl_spec_map = {}
	for option, seq in pairs(seq_option_map) do
		for i, val in ipairs(seq) do
			if hl_spec_map[i] == nil then
				hl_spec_map[i] = {}
			end
			hl_spec_map[i][option] = val
		end
	end

	return starcolor.text_color_group(ns_key, hl_spec_map)
end

starcolor.get_color = function (group, key)
	local full_key = get_full_key(group.ns_key, key)
	return group.colors[full_key]
end

starcolor.color_frag = function (group, key, buffer, line, start_col, len)
	local end_col = -1
	if len ~= nil then
		end_col = start_col + len
	end

	if group ~= nil then
		local full_key = get_full_key(group.ns_key, key)
		local color = group.colors[full_key]

		if color == nil then
			return
		end
		if not color.is_init then
			vim.api.nvim_set_hl(0, full_key, color.hl_spec)
			color.is_init = true
		end
		vim.api.nvim_buf_add_highlight(buffer, 0, full_key, line, start_col, end_col)
	else
		vim.api.nvim_buf_add_highlight(buffer, 0, key, line, start_col, end_col)
	end
end

starcolor.color_line = function (group, key, buffer, line)
	starcolor.color_frag(group, key, buffer, line, 0)
end

starcolor.color_lines_seq = function (group, buffer, start_line, count)
	for i = 1, count do
		starcolor.color_line(group, i, buffer, start_line + i - 1)
	end
end

return starcolor
