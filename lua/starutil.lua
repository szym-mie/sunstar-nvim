local starutil = {}

function starutil.get_path_normal_form (url)
	local path = string.gsub(string.gsub(url, '\\', '/'), '/$', '')
	return starutil.str_from_iter(string.gmatch(path, '/[^/]+'))
end

function starutil.is_file (path)
	return vim.fn.filereadable(path) ~= 0
end

function starutil.is_directory (path)
	return vim.fn.isdirectory(path) ~= 0
end

function starutil.is_in_directory (path, filepath)
	return string.match(filepath, '^'..path..'/')
end

function starutil.get_current_directory ()
	local current_filepath = starutil.get_path_normal_form(vim.fn.expand('%:p'))
	return starutil.file_directory(current_filepath)
end

function starutil.file_directory (path)
	return string.match(path, '.*/')
end

function starutil.file_name (path)
	return string.match(path, '([^/]+$)')
end

function starutil.open_file_in_new_tab (path)
	vim.cmd('tabe '..path)
end

function starutil.identity (n)
	return n
end

function starutil.list_from_iter (iter)
	local list = {}
	for elem in iter do
		table.insert(list, elem)
	end
	return list
end

function starutil.str_from_iter (iter)
	local str = ''
	for elem in iter do
		str = str..elem
	end
	return str
end

function starutil.list_map (list, fn)
	local new_list = {}
	for _, elem in ipairs(list) do
		table.insert(new_list, fn(elem))
	end
	return new_list
end

function starutil.list_filter (list, pred)
	local new_list = {}
	for _, elem in ipairs(list) do
		if pred(elem) then
			table.insert(new_list, elem)
		end
	end
	return new_list
end

function starutil.list_any (list, pred)
	for _, elem in ipairs(list) do
		if pred(elem) then
			return true
		end
	end
	return false
end

function starutil.list_all (list, pred)
	for _, elem in ipairs(list) do
		if pred(elem) then
			return false
		end
	end
	return true
end

function starutil.list_find_first (list, pred)
	for _, elem in ipairs(list) do
		if pred(elem) then
			return elem
		end
	end
	return nil
end

function starutil.get_open_buffers_ids ()
	local buffers_ids = {}
	for _, buffer_info in ipairs(vim.fn.getbufinfo()) do
		local buffer_id = buffer_info.bufnr
		local is_listed = buffer_info.listed
		local window_count = #buffer_info.windows
		vim.print(buffer_id)
		vim.print(is_listed)
		vim.print(window_count)
		if is_listed and window_count > 0 then
			vim.print('add '..buffer_id)
			table.insert(buffers_ids, buffer_id)
		end
	end
	return buffers_ids
end

function starutil.get_buffer_filename (buffer_id)
	return vim.api.nvim_buf_get_name(buffer_id)
end

function starutil.read_flat_config (filepath)
	local abs_filepath = vim.fn.stdpath('config')..'/'..filepath
	local lines = vim.fn.readfile(abs_filepath)
	local values = {}
	for _, line in ipairs(lines) do
		local comment_start, _ = string.find(line, '#')
		local line_end = comment_start or 0
		local value = string.gsub(string.sub(line, 1, line_end - 1), '%s', '')
		table.insert(values, value)
	end
	return values
end

return starutil
