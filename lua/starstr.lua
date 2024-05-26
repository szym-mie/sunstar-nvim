--- Common string manipulation
local starstr = {}

--- Get length of string.
--- @param str string string
--- @return number length number of chars in string
function starstr.length (str)
	return string.len(str)
end

--- Repeat string a few times.
--- @param str string string
--- @param n number how much times
--- @return string new_str 'str' repeated 'n' times
function starstr.times (str, n)
	local new_str = ''
	for _ = 1, n do
		new_str = new_str..str
	end

	return new_str
end

--- Split string at char, produces empty strings.
--- @param str string string
--- @param ch string char to split at
--- @return table parts parts of a string
function starstr.split (str, ch)
	local pattern = '([^'..ch..']*)'
	local parts = {}
	for part in string.gmatch(str, pattern) do
		table.insert(parts, part)
	end

	return parts
end

--- Replace pattern with a replacement string.
--- @param str string string
--- @param pattern string pattern to be replaced
--- @param replace string replacement string
--- @return string replace_str new string
function starstr.replace (str, pattern, replace)
	local replace_str, _ = string.gsub(str, pattern, replace)
	return replace_str
end

--- Place a string inside another string.
--- @param str string string
--- @param patch string patch to be placed
--- @param index number position of new string
--- @param padding number? number of chars from both sides, which will pad the string
--- @param align string? aligment of the string: 'left', 'center', 'right'
--- @return string new_str string with a placed element
function starstr.place (str, patch, index, padding, align)
	local new_str = str
	local str_len = starstr.length(str)
	local patch_len = starstr.length(patch)

	local function place_str(start_index, end_index)
		return string.sub(str, 1, start_index)..patch..string.sub(str, end_index)
	end

	padding = padding or 0
	align = align or 'left'

	local place_len = str_len - padding * 2

	if align == 'left' then
		local start_index = math.max(
			math.min(index, place_len - patch_len),
			padding
		)
		local end_index = math.min(
			start_index + patch_len,
			str_len - padding
		)
		new_str = place_str(start_index, end_index)
	elseif align == 'center' then
		-- TODO	
	elseif align == 'right' then
		-- TODO
	else
		new_str = ''
	end

	return new_str
end

return starstr
