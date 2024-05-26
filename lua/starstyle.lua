local starstyle = {}

local function get_full_key(ns_key, key)
	return ns_key..'_'..key
end

function starstyle.rgb (r, g, b)
	return string.format('#%02x%02x%02x', r, g, b)
end

function starstyle.rgb_vec (vec)
	return starstyle.rgb(vec.r, vec.g, vec.b)
end

local function lerp(a, b, r)
	return a * (1 - r) + b * r
end

function starstyle.lerp_vec (vec_a, vec_b, r)
	return {
		r = lerp(vec_a.r, vec_b.r, r),
		g = lerp(vec_a.g, vec_b.g, r),
		b = lerp(vec_a.b, vec_b.b, r),
	}
end

function starstyle.gradient (from, to, steps)
	local colors = {}
	for i = 1, steps do
		local src_mul = (i - 1) / (steps - 1)
		local color_vec = starstyle.lerp_vec(from, to, src_mul)
		table.insert(colors, starstyle.rgb_vec(color_vec))
	end

	return colors
end

function starstyle.style_group (ns_key, hl_spec_map)
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

function starstyle.style_group_from_seqs (ns_key, seq_option_map)
	local hl_spec_map = {}
	for target, seq in pairs(seq_option_map) do
		for i, val in ipairs(seq) do
			if hl_spec_map[i] == nil then
				hl_spec_map[i] = {}
			end
			hl_spec_map[i][target] = val
		end
	end

	return starstyle.style_group(ns_key, hl_spec_map)
end

function starstyle.get_color (group, key)
	local full_key = get_full_key(group.ns_key, key)
	return group.colors[full_key]
end

function starstyle.color_frag (group, key, buffer, line, start_col, len)
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

function starstyle.color_line (group, key, buffer, line)
	starstyle.color_frag(group, key, buffer, line, 0)
end

function starstyle.color_lines_seq (group, buffer, start_line, count)
	for i = 1, count do
		starstyle.color_line(group, i, buffer, start_line + i - 1)
	end
end

function starstyle.color(group, buffer, start_col, start_line, end_col, end_line)
	if start_line == end_line then
		local len = end_col - start_col
		starstyle.color_frag(group, 1, buffer, start_line, start_col, len)
	else
		local keys = #group
		local last = math.min(end_line - start_line, keys)
		starstyle.color_frag(group, 1, buffer, start_line, start_col)
		starstyle.color_frag(group, last, buffer, end_line, 0, end_col)
		for line = start_line + 1, end_line - 1 do
			local key = math.min(line - start_line + 1, keys)
			starstyle.color_line(group, key, buffer, line);
		end
	end
end

return starstyle
