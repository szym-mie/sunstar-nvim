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

return starutil
