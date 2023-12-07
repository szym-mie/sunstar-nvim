local starstore = {
	stores = {}
}

local starutil = require('starutil')

local function assoc_in (obj, keys, val)
	local curr_obj = obj
	local val_key = table.remove(keys, #keys)
	for _, key in ipairs(keys) do
		if curr_obj[key] == nil then
			curr_obj[key] = {}
		end
		curr_obj = curr_obj[key]
	end
	curr_obj[val_key] = val
end

local function get_in (obj, keys)
	local curr_obj = obj
	for _, key in ipairs(keys) do
		if curr_obj == nil then
			return nil
		end
		curr_obj = curr_obj[key]
	end
	return curr_obj
end

local function add_key (keys, key)
	local new_keys = {}
	local i = 1
	for _, prev_key in ipairs(keys) do
		new_keys[i] = prev_key
		i = i + 1
	end
	new_keys[i] = key
	return new_keys
end

local function flat_iter_in (obj, fn)
	for key, val in pairs(obj) do
		if type(val) == 'table' then
			local pre_key_fn = function (k, v) fn(add_key(key, k), v) end
			flat_iter_in(val, pre_key_fn)
		else
			fn(key, val)
		end
	end
end

local function merge_in (obj1, obj2)
	local obj = {}
	local assoc_in_obj = function (k, v) assoc_in(obj, k, v) end
	flat_iter_in(obj1, assoc_in_obj)
	flat_iter_in(obj2, assoc_in_obj)
	return obj
end

local function is_illegal_qname (qname)
	local is_illegal = string.match(qname, '[^%.a-zA-Z0-9_]') ~= nil
	if is_illegal then error('qname \''..qname..'\' contains illegal chars') end
end

function starstore.get_qname (keys)
	local qname = ''
	for i, key in ipairs(keys) do
		is_illegal_qname(key)
		if i == 1 then
			qname = key
		else
			qname = qname..'.'..key
		end
	end
	return qname
end

function starstore.qname_of (qname)
	is_illegal_qname(qname)
	local qname_iter = string.gmatch(qname, '[^%.]+')
	return starutil.list_from_iter(qname_iter)
end

local function read_lines (lines)
	local obj = {}
	for _, line in ipairs(lines) do
		local sep_index = string.find(line, '%s*:')
		if sep_index ~= nil then
			local full_key_name = string.sub(line, 1, sep_index - 1)
			local keys = starstore.qname_of(full_key_name)
			local rval = string.sub(line, sep_index + 1, -1)
			local val_s, val_e = string.find(rval, '\'.*\'')
			if val_s ~= nil then
				local val = string.sub(rval, val_s + 1, val_e - 1)
				assoc_in(obj, keys, val)
			end
		end
	end
	return obj
end

local function write_lines (obj, prev_lines)
	local prev_obj = read_lines(prev_lines)
	local merge_obj = merge_in(prev_obj, obj)
	local lines = {}
	flat_iter_in(merge_obj, function (k, v)
		local qk = starstore.get_qname(k)
		table.insert(lines, qk..': \''..v..'\'')
	end)
	return lines
end

local function read_apply (lines, apply_callbacks)
	local obj = read_lines(lines)
	if apply_callbacks ~= nil then
		for key, value in pairs(obj) do
			local apply_fn = apply_callbacks[key]
			if apply_fn ~= nil then
				pcall(apply_fn, value)
			end
		end
	end
	return obj
end

function starstore.setup (_)
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

local function try_read_store (store)
	local filepath = store.filepath
	if not starutil.is_file(filepath) then
		return nil
	end
	return vim.fn.readfile(filepath)
end

local function try_write_store (store, obj)
	local filepath = store.filepath
	vim.fn.writefile(obj, filepath)
end

function starstore.reload (store)
	local lines = try_read_store(store)
	if lines ~= nil then
		store.items = read_apply(lines, store.apply_callbacks)
		return true
	end
	store.items = {}
	return false
end

function starstore.write (store)
	local lines = try_read_store(store) or {}
	try_write_store(store, write_lines(store.items, lines))
end

function starstore.overwrite (store)
	try_write_store(store, write_lines(store.items, {}))
end

function starstore.get (store, keys)
	return get_in(store.items, keys)
end

function starstore.foreach (store, fn)
	flat_iter_in(store.items, fn)
end

function starstore.set (store, keys, value, reapply)
	local qname = starstore.get_qname(keys)
	assoc_in(store.items, keys, value)
	if reapply and store.apply_callbacks ~= nil then
		local apply_fn = store.apply_callbacks[qname]
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

