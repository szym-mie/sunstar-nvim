---A complete framework, allowing to react to events such as saves, tab
---& buffer changes, and notably other star-system events - sort of as a 
---message bus.

local starevent = {
	channels = {}
}

local vim_events = {
	'BufAdd',
	'BufDelete',
	'BufEnter',
	'BufFilePost',
	'BufFilePre',
	'BufHidden',
	'BufLeave',
	'BufModifiedSet',
	'BufNew',
	'BufNewFile',
	'BufRead',
	'BufReadPost',
	'BufReadCmd',
	'BufReadPre',
	'BufUnload',
	'BufWinEnter',
	'BufWinLeave',
	'BufWipeout',
	'BufWrite',
	'BufWritePre',
	'BufWriteCmd',
	'BufWritePost',
	'ChanInfo',
	'ChanOpen',
	'CmdUndefined',
	'CmdlineEnter',
	'CmdlineLeave',
	'CmdwinEnter',
	'CmdwinLeave',
	'ColorScheme',
	'ColorSchemePre',
	'CompleteChanged',
	'CompleteDonePre',
	'CompleteDone',
	'CursorHold',
	-- TODO
}

---@class Message
---@field type string
---@field about string
---@field payload ?string
---@field where ?string
---@field reason ?string

function starevent.add_channel (id, owner)
	local channel = {
		owner = owner,
		msgs = {},
		next_msg_id = 1,
		observers = {}
	}

	if not starevent.has_channel(id) then
		starevent.channels[id] = channel
	else
		error('channel \''..id..'\' already created')
	end
end

function starevent.has_channel (id)
	return starevent.get_channel(id) ~= nil
end

function starevent.get_channel (id)
	return starevent.channels[id]
end

local function notify (channel, msg)
	for _, observer in ipairs(channel.observers) do
		-- TODO implement better filters
		if observer.filter == nil or observer.filter[msg.about] ~= nil then
			observer.msg_fn(msg)
		end
	end
end

---Primitive method for broadcasting message on channel of ID
---@param id string channel ID
---@param msg Message message to send
---@return boolean was_sent has the message been sent
function starevent.push_message (id, msg)
	if starevent.has_channel(id) then
		local channel = starevent.get_channel(id)
		channel.msgs[channel.next_msg_id] = msg
		channel.next_msg_id = channel.next_msg_id + 1
		notify(channel, msg)
		return true
	end
	return false
end

---Send an information to a channel referenced by ID 
---@param id string channel ID
---@param about string topic of this info
---@param payload any
---@return boolean was_sent has the message been sent
function starevent.info (id, about, payload)
	local msg = {
		type = 'info',
		about = about,
		payload = payload
	}
	return starevent.push_message(id, msg)
end

---Send a warning to a channel referenced by ID
---@param id string channel ID
---@param about string topic of this warning
---@param where any function, line of this warning
---@param reason string reason for the warning
---@return boolean was_sent has the message been sent
function starevent.warn (id, about, where, reason)
	local msg = {
		type = 'warn',
		about = about,
		where = where,
		reason = reason
	}
	return starevent.push_message(id, msg)
end

function starevent.set_event_source (id, event)
	vim.api.nvim_create_autocmd({ event }, {
		callback = function (ev)
			local ev_payload = {
				value = ev.match,
				buffer = ev.buf,
				file = ev.file
			}
			starevent.info(id, event, ev_payload)
		end
	})
end

function starevent.observe (id, msg_fn, filter)
	if starevent.has_channel(id) then
		local channel = starevent.get_channel(id)
		local observer = {
			msg_fn = msg_fn,
			filter = filter
		}
		table.insert(channel.observers, observer)
		return true
	end
	return false
end

function starevent.unobserve (id, msg_fn)
	if starevent.has_channel(id) then
		local channel = starevent.get_channel(id)
		for i, observer in ipairs(channel.observers) do
			if observer.msg_fn == msg_fn then
				table.remove(channel, i)
				return true
			end
		end
	end
	return false
end

function starevent.setup (opts)
	if not opts.exclude_vim_events then
		for channel_name, vim_event in pairs(vim_events) do
			starevent.add_channel(channel_name, 'vim')
			starevent.set_event_source(channel_name, vim_event)
		end
	end
end

return starevent
