---Support for window agnostic pages of text
local starpage = {}

local starstr = require('starstr')
local starstyle = require('lua.starstyle')

---Page
---@class Page
---@field id string id of this page
---@field elems table element list

--- Page element
---@class Element
---@field elem string element type
---@field text string element inner text
---@field class string style class id
---@field action function action to be taken on click or action key press
---@field action_key string key to trigger action
---@field props table additional properties for actions/extra metadata

---Empty action function
---@param _ Element target element
local function action_noop(_) end

---Follow link action function
---allows to navigate to a different page TODO
---@param elem Element target element
local function action_follow_link(elem)
	vim.print(elem.props.href)
end

---Low-level create a new element for the page
---@param elem string element type
---@param text string element inner text
---@param render function function to render this element based on its properties
---@param style ?string style class ID
---@param action ?function action to be taken on click or action key press
---@param action_key ?string key to trigger action
---@param props ?table additional properties for actions/extra metadata
---@return Element new_element new element ready to be used on a page
local function create_element(elem, text, render, style, action, action_key, props)
	return {
		elem = elem,
		text = text,
		render = render,
		style = style,
		action = action or action_noop,
		action_key = action_key or nil,
		props = props or {}
	}
end

---Create a new page
---@param id string page ID send in navigation
---@param ... table elements list
---@return Page new_page page with elements
function starpage.page(id, ...)
	local elems = {}
	for i, v in ipairs(...) do
		elems[i] = v
	end

	return {
		id = id,
		elems = elems
	}
end

local button_style = starstyle.style_group('page_hl', { reverse = true })
local link_style = starstyle.style_group('page_hl', { underline = true })

local function render_button(elem)
	local width = elem.props.width - 4
	return '[ ' .. starstr.times(' ', width) .. ' ]'
end

function starpage.button(text, action, action_key, class)
	return create_element(
		'button', text,
		render_button,
		class,
		action, action_key
	)
end

local function render_text(elem)
	return elem.text_lines
end

function starpage.text(text, class)
	return create_element(
		'text', text,
		render_text,
		class,
		action_noop, nil
	)
end

local function render_link(elem)
	return elem.text_lines
end


function starpage.link(text, href, class)
	return create_element(
		'link', text,
		render_link,
		class,
		action_follow_link, nil,
		{ href = href }
	)
end

---Get layout dimensions of text block.
---  rows - number of lines,
---  cols - number of columns of last line
---@param text_lines table lines of text
---@return table dimensions dimensions of block
local function get_text_layout_params(text_lines)
	return {
		rows = #text_lines,
		cols = starstr.length(text_lines[#text_lines])
	}
end

---Format text, expand newlines and tabs
---@param text string input text
---@param opts table options
---@return table text_lines lines of text
local function format_text(text, opts)
	local spaces_per_tab = opts.spaces_per_tab or 4
	local tab_str = starstr.times(' ', spaces_per_tab)
	local raw_text = starstr.replace(text, '\t', tab_str)
	local lines = starstr.split(raw_text, '\n')
	if opts.first_line then
		if #lines > 0 then
			return { lines[1] }
		else
			return {}
		end
	end
	if opts.one_line then
		return { starstr.replace(raw_text, '\n', ' ') }
	end
	return lines
end

local function apply_elem(elem)

end

---Render a page
---@param page Page page to render
---@param buffer number buffer id
---@param opts table render options
function starpage.render(page, buffer, opts)
	local x = 0
	local y = 0
	for _, elem in ipairs(page.elems) do
		local color_group = nil -- TODO
		local elem_lines = format_text(elem.page, opts)
		local elem_layout_params = get_text_layout_params(elem_lines)
		local nx = elem_layout_params.cols;
		local ny = y + elem_layout_params.rows - 1;
		starstyle.color(color_group, buffer, x, y, nx, ny)
	end
end

return starpage
