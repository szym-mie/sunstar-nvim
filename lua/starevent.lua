-- A complete framework, allowing to react to events such as saves, tab
-- & buffer changes, and notably other star-system events - sort of as a 
-- message bus.
local starevent = {
	channels = {}
}

local vim_events = {
	-- TODO
}

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
	for _, obs_msg_fn in ipairs(channel.observers) do
		obs_msg_fn(msg)
	end
end

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

function starevent.message (id, from, payload)
	local msg = {
		type = 'msg',
		from = from,
		payload = payload
	}
	return starevent.push_message(id, msg)
end

function starevent.error (id, where, reason)
	local msg = {
		type = 'err',
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
			starevent.message(id, ev_payload)
		end
	})
end

function starevent.observe (id, msg_fn)
	if starevent.has_channel(id) then
		local channel = starevent.get_channel(id)
		table.insert(channel.observers, msg_fn)
		return true
	end
	return false
end

function starevent.unobserve (id, msg_fn)
	if starevent.has_channel(id) then
		local channel = starevent.get_channel(id)
		for i, obs_msg_fn in ipairs(channel.observers) do
			if obs_msg_fn == msg_fn then
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
