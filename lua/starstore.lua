local starstore = {
	stores = {}
}

local starutil = require('starutil')

local function assoc_in(tab, keys, val)
	local curr_tab = tab
	local val_key = table.remove(keys, #keys)
	for _, key in ipairs(keys) do
		if curr_tab[key] == nil then
			curr_tab[key] = {}
		end
		curr_tab = curr_tab[key]
	end
	curr_tab[val_key] = val
end

local function get_in(tab, keys)
	local curr_tab = tab
	for _, key in ipairs(keys) do
		if curr_tab == nil then
			return nil
		end
		curr_tab = curr_tab[key]
	end
	return curr_tab
end

local function flat_iter_in(tab, fn)
	for key, val in pairs(tab) do
		if type(val) == 'table' then
			local pre_key_fn = function (k, v) fn(key..'.'..k, v) end
			flat_iter_in(val, pre_key_fn)
		else
			fn(key, val)
		end
	end
end

local function read_lines(lines)
	local tab = {}
	for _, line in ipairs(lines) do
		local sep_index = string.find(line, '%s*:')
		if sep_index ~= nil then
			local full_key_name = string.sub(line, 1, sep_index - 1)
			local qname_iter = string.gmatch(full_key_name, '[^%.]+')
			local qnames = starutil.list_from_iter(qname_iter)
			local rval = string.sub(line, sep_index + 1, -1)
			local val_s, val_e = string.find(rval, '\'.*\'')
			if val_s ~= nil then
				local val = string.sub(rval, val_s + 1, val_e - 1)
				assoc_in(tab, qnames, val)
			end
		end
	end
	return tab
end

local function write_lines(tab)
	local lines = {}
	flat_iter_in(tab, function (k, v)
		table.insert(lines, k..': \''..v..'\'')
	end)
	return lines
end

local function read_apply(lines, apply_callbacks)
	local store = read_lines(lines)
	if apply_callbacks ~= nil then
		for key, value in pairs(store) do
			local apply_fn = apply_callbacks[key]
			if apply_fn ~= nil then
				pcall(apply_fn, value)
			end
		end
	end
	return store
end

function starstore.setup (opts)
	vim.api.nvim_create_autocmd({'VimLeave'}, {
		callback = function (_)
			for _, store in ipairs(starstore.stores) do
				starstore.write(store)
			end
		end
	})
end

function starstore.new (opts)
	local store = {
		items = {},
		filepath = opts.filepath,
		apply_callbacks = opts.apply_callbacks,
	}
	starstore.reload(store)
	if not opts.untracked then
		table.insert(starstore.stores, store)
	end
	return store
end

function starstore.in_config_path (filename)
	return vim.fn.stdpath('config')..'/'..filename
end

function starstore.reload (store)
	local filepath = store.filepath
	if not starutil.is_file(filepath) then
		return false
	end
	local lines = vim.fn.readfile(filepath)
	if lines then
		store.items = read_apply(lines, store.apply_callbacks)
	else
		store.items = {}
	end
	return true
end

function starstore.get_qname (keys)
	local qname = ''
	for i, key in ipairs(keys) do
		if i == 1 then
			qname = key
		else
			qname = qname..'.'..key
		end
	end
	return qname
end

function starstore.write (store)
	local filepath = store.filepath
	vim.fn.writefile(write_lines(store.items), filepath)
end

function starstore.get (store, keys)
	if type(keys) == 'table' then
		return get_in(store.items, keys)
	else
		return get_in(store.items, { tostring(keys) })
	end
end

function starstore.foreach (store, fn)
	flat_iter_in(store.items, fn)
end

function starstore.set (store, keys, value, reapply)
	assoc_in(store.items, keys, value)
	if reapply and store.apply_callbacks ~= nil then
		local apply_fn = store.apply_callbacks[starstore.get_qname(keys)]
		if apply_fn ~= nil then
			apply_fn(value)
		end
	end
end

function starstore.get_bool (store, key)
	return starstore.get(store, key) == 'true'
end

function starstore.set_bool (store, key, value, reapply)
	if value then
		starstore.set(store, key, 'true', reapply)
	else
		starstore.set(store, key, 'false', reapply)
	end
end

return starstore

