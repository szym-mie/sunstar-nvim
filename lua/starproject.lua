local starproject = {
	opened_projects = {},
	recent_projects_limit = 10,
	recent_projects_store_path = 'recent_projects.store',
	recent_projects_store = nil,
}

local starstore = require('starstore')
local starutil = require('starutil')
local starwindow = require('starwindow')
local starcolor = require('starstyle')

function starproject.setup (opts)
	if opts.recent_projects_limit ~= nil then
		starproject.recent_projects_limit = opts.recent_projects_limit
	end
	if opts.recent_projects_store_path ~= nil then
		starproject.recent_projects_store_path = opts.recent_projects_store_path
	end

	starproject.recent_projects_store = starstore.new({
		filepath = starproject.recent_projects_store_path
	})
end

function starproject.get_recent_projects ()
	local store = starproject.recent_projects_store
	local projects = {}
	for i = 1, starproject.recent_projects_limit do
		projects[i] = starstore.get(store, starstore.qname_of(i))
	end
	starproject.recent_projects = projects
end

function starproject.update_recent_projects ()
	local store = starproject.recent_projects_store
	local projects = starproject.recent_projects
	for i = 1, starproject.recent_projects_limit do
		starstore.set(store, starstore.qname_of(i), projects[i])
	end
	starstore.write(store)
end

local function append_item (list, path)
	table.insert(list, path)
end

local function move_item (list, i)
	local item = table.remove(list, i)
	table.insert(list, item)
end

local function update_item (list, path)
	for i, item in ipairs(list) do
		if item == path then
			move_item(list, i)
			return false
		end
	end

	append_item(list, path)
	return true
end

function starproject.opened_any (path)
	local file_path = starutil.get_path_normal_form(path)
	if starutil.is_directory(path) then
		update_item(starproject.opened_projects, file_path)
		return true
	elseif starutil.is_file(path) then
		if starproject.is_path_in_any_project(path) then
			return false
		end
		return false
	end

	starproject.write()
end

local function new_project_store (project_path)
	vim.print(project_path)
	local project_filepath = starutil.get_path_normal_form(project_path)
	vim.print(project_filepath)
	if not starutil.is_directory(project_filepath) then
		return nil
	end
	return starstore.new({
		filepath = project_filepath..'/.project.store',
		discard_on_exit = true,
	})
end

local function update_project_store_files (files, store)
	starstore.clear_all(store)
	starstore.set(store, { 'files' }, files, false)
end

local function open_project_store (path, is_new)
	local project_store = new_project_store(path)
	if project_store == nil then
		return nil
	end
	if not project_store.has_file or is_new then
		return nil
	end
	table.insert(starproject.opened_projects, project_store)
	return project_store
end

function starproject.create_project (path)
	local project_store = open_project_store(path, true)
	if project_store == nil then
		-- error
		return
	end
	starproject.save_project(project_store.filepath)
end

function starproject.open_project (path)
	local project_store = open_project_store(path)
	if project_store == nil then
		-- error
		return
	end
	local project_items = starstore.get(project_store, { 'files' })
	vim.print(project_items)
	if project_items == nil then
		return nil
	end
	for _, item_path in pairs(project_items) do
		starutil.open_file_in_new_tab(item_path)
	end
end

function starproject.save_project (path)
	local project_store = open_project_store(path)
	while project_store == nil do
		-- TODO check if not infinite
		path = starutil.get_path_normal_form(starutil.file_directory(path))
		vim.print(path)
		project_store = open_project_store(path)
	end

	local buffer_ids = starutil.get_open_buffers_ids()
	local filenames = starutil.list_map(buffer_ids, starutil.get_buffer_filename)
	local normal_filepaths = starutil.list_map(filenames, starutil.get_path_normal_form)

	local project_path = starutil.get_path_normal_form(starutil.file_directory(project_store.filepath))
	vim.print(project_path)
	local is_in_project = function (file_path)
		return starutil.is_in_directory(project_path, file_path)
	end
	for _, fpath in ipairs(normal_filepaths) do
		vim.print(fpath)
		vim.print(is_in_project(fpath) and 'in' or 'out')
	end

	local project_filepaths = starutil.list_filter(normal_filepaths, is_in_project)
	for _, fpath in ipairs(project_filepaths) do
		vim.print(fpath)
	end
	update_project_store_files(project_filepaths, project_store)
	starproject.write_project_file(project_store)
end

function starproject.read_project_file (store)
	starstore.reload(store)
end

function starproject.write_project_file (store)
	starstore.overwrite(store)
end

function starproject.update_buffer (buffer)
	local limit = starproject.items_limit
	local projects_title_line = 0
	local lines = {'Projects', ''}
	for i = 1, limit do
		local item = starproject.projects[i]
		if item == nil then
			break
		end
		local line = string.format('[%02d] %s', i, item)
		table.insert(lines, line)
	end

	table.insert(lines, '')

	starwindow.update_text_buffer(buffer, lines)
	starcolor.color_line_raw('keyword', buffer, projects_title_line)
end

function starproject.create_window ()
	-- starwindow.set_ui(nil, )
end

return starproject
