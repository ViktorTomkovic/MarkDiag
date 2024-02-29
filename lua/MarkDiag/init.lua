local MarkDiag = {}

MarkDiag.setup = function ()
	print("MarkDiag.setup() called")
	-- Custom namespace so we don't mess with other diagnostics.
	MarkDiag.namespace = vim.api.nvim_create_namespace("MarkDiag")
	-- Autocommand which will run the diagnosis
	vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "CursorHold"},
		{
			group = vim.api.nvim_create_augroup("MarkDiag", { clear = true }),
			pattern = "*",
			callback = MarkDiag.checkCurrentBuffer,
		})
end

MarkDiag.checkCurrentBuffer = function ()
	if (not vim.w.MarkDiagEnabled) then
		return
	end
	--print("MarkDiag checkCurrentBuffer call")
	-- Reset all previous diagnostics
	vim.diagnostic.reset(MarkDiag.namespace, 0)
	--print(Dump(markPos))
	local diags = {}
	local i = 1
	for c in ([[abcd(){}[]<>.'"^]]):gmatch(".") do
		local ok, diagMsg = MarkDiag.createDiagEntryForMark(c)
		if (ok) then
			-- print("Setting mark a diag at " .. line .. ":" .. column)
			diags[i] = diagMsg
			i = i + 1
		end
	end
	-- put diags in same line together
	local diag2 = {}
	for _, markDiag in ipairs(diags) do
		local ld = diag2[markDiag.line]
		if (ld == nil) then
			ld = markDiag
		else
			ld.message = ld.message..markDiag.message
		end
	end
	vim.diagnostic.set(MarkDiag.namespace, 0, diag2)
end
-- @param mark string
MarkDiag.createDiagEntryForMark = function (mark)
	local pos=nil
	if (mark == "]") then
		pos = vim.fn.getpos("']")
	else
		pos = vim.fn.getpos("'"..mark.."]]")
	end

	local bufnr = pos[1]
	local line = pos[2]
	local column = pos[3]
	local bufOff = pos[4]
	--print (vim.fn.bufnr("%") .. "==" .. bufnr)
	--if (vim.fn.bufnr(vim.fn.bufname("%")) == bufnr) then
	if (bufnr ~= 0) then
		-- Don't show marks which are set in other buffers
		line = 0
	end
	if (line > 0 and bufOff == 0) then
		return true, {
			lnum = tonumber(line)-1,
			--end_lnum = tonumber(line)-1,
			col = tonumber(column)-1,
			--end_col = tonumber(column)-1,
			message = mark,
			severity = vim.diagnostic.severity.HINT,
		}
	else
		return false, {}
	end
end
MarkDiag.disable = function ()
	vim.diagnostic.reset(MarkDiag.namespace, 0)
	vim.w.MarkDiagEnabled = false
end
MarkDiag.enable = function ()
	vim.w.MarkDiagEnabled = true
	MarkDiag.checkCurrentBuffer()
end
MarkDiag.toggle = function ()
	if (vim.w.MarkDiagEnabled) then
		MarkDiag.disable()
	else
		MarkDiag.enable()
	end
end
return MarkDiag
