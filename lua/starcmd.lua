local starcmd = {}

function starcmd.silent_cmd (cmd)
	pcall(function (vim_cmd) vim.cmd(vim_cmd) end, cmd)
end

function starcmd.cmd_callback (run, name)
	local run_type = type(run)
	if run_type == 'string' then
		return function ()
			starcmd.silent_cmd(run)
		end
	elseif run_type == 'function' then
		return run
	else
		return function ()
			vim.print('cmd \''..name..'\' of type '..run_type..' cannot be executed')
		end
	end
end

return starcmd
