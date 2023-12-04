local core_config = {}

core_config.setup = function (opts)
	vim.o.number = true
	vim.o.relativenumber = true
	vim.o.showtabline = 2
end

return core_config
