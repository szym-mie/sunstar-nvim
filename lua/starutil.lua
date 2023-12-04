local starutil = {}

starutil.get_path_normal_form = function (path)
	return string.gsub(string.gsub(path, '\\', '/'), '/$', '')
end

starutil.is_file = function (path)
	return vim.fn.filereadable(path) ~= 0
end

starutil.is_directory = function (path)
	return vim.fn.isdirectory(path) ~= 0
end

starutil.file_directory = function (path)
	return string.match(path, '([^\\/]+\\/)+')
end

starutil.file_name = function (path)
	return string.match(path, '([^\\/]+\\/?$)')
end

starutil.identity = function (n)
	return n
end

starutil.list_from_iter = function (iter)
	local list = {}
	for elem in iter do
		table.insert(list, elem)
	end
	return list
end

return starutil
