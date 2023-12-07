local starproject = {
	opened_projects = {},
	recent_projects_limit = 10,
	recent_projects_store_path = 'recent_projects.store.txt',
	recent_projects_store = nil,
}

local starstore = require('starstore')
local starutil = require('starutil')
local starwindow = require('starwindow')
local starcolor = require('starcolor')

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

function starproject.new (opts)
	return {
		path = opts.path,
		files = {},
		tasks = {},
	}
end

local function new_project_store (project)
	return starstore.new({
		filepath = project.path
	})
end

local function update_project_store (project, store)
	-- TODO
end

function starproject.create_project (path)
	local project = starproject.new({ path = path })
	local store = new_project_store(project)
end

function starproject.open_project ()
	 
end

function starproject.save_project ()
	
end

function starproject.read_project_file ()
	
end

function starproject.write_project_file ()
	
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
