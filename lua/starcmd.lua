local starcmd = {}

starcmd.silent_cmd = function (cmd)
	pcall(function (vim_cmd) vim.cmd(vim_cmd) end, cmd)
end

starcmd.cmd_callback = function (run, name)
	if type(run) == 'string' then
		return function ()
			starcmd.silent_cmd(run)
		end
	elseif type(run) == 'function' then
		return run
	else
		return function ()
			vim.print('cmd \''..name..'\' cannot be executed')
		end
	end
end

return starcmd
