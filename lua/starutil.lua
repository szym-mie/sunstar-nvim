local starutil = {}

function starutil.get_path_normal_form (path)
	return string.gsub(string.gsub(path, '\\', '/'), '/$', '')
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

function starutil.file_directory (path)
	return string.match(path, '([^\\/]+\\/)+')
end

function starutil.file_name (path)
	return string.match(path, '([^\\/]+\\/?$)')
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

function starutil.list_map (list, fn)
	local new_list = {}
	for _, elem in ipairs(list) do
		table.insert(new_list, fn(elem))
	end
	return new_list
end

function starutil.get_open_buffers_ids ()
	local buffers_ids = {}
	for buffer_id = 1, vim.fn.bufnr('$') do
		local is_listed = vim.fn.buflisted(buffer_id) == 1
		if is_listed then
			table.insert(buffers_ids, buffer_id)
		end
	end
	return buffers_ids
end

function starutil.get_buffer_filename (buffer_id)
	return vim.api.nvim_buf_get_name(buffer_id)
end

return starutil
