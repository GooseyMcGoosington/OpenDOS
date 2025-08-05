local comp, comp_list, comp_type, invoke = component, component.list, component.type, component.invoke
local bootAddr, shutdown, uptime, pullSignal, totalMem, freeMem, beep = computer.getBootAddress(), computer.shutdown, computer.uptime, computer.pullSignal, computer.totalMemory, computer.freeMemory, computer.beep
local loadfile = ...

_G.gpu, _G.screen, _G.components = {}, {}, {}
_G.bootAddress, _G.bootgpu, _G.bootscreen = bootAddr, nil, nil
_G.screenbuffer, _G.filesystem, _G.wh = {}, nil, {0,0}
_G.shell = {currentLine=1, fault=-1, dump="UNKNOWN ERROR REPORTED"}

_G.package = {keyboard=nil, command=nil, utility=nil, fileeditor=nil}
_G.invoke = invoke

local faults = {
	[0]="FATAL: Vital Fault", [1]="FATAL: System Fault",
	[2]="FATAL: Out of Memory", [3]="FATAL: Hardware Fault",
	[4]="KERNEL: Software Load Failure", [5]="KERNEL: Software Exception",
	[6]="FATAL: Disk Failure"
}

computer.shutdown = function(reboot)
	if os.sleep then computer.pushSignal("shutdown"); os.sleep(0.1) end
	shutdown(reboot)
end

local function findComp()
	for addr, type in comp_list() do
		local t = {address=addr, ctype=type}
		if type == "gpu" then table.insert(_G.gpu, t)
		elseif type == "screen" then table.insert(_G.screen, t)
		else table.insert(_G.components, t) end
	end
end

local function mountFS(addr)
	local path = "./mnt/"..addr:sub(1,8).."/"
	local ok, err = _G.filesystem.mount(path, addr)
	if not ok then _G.shell.text(err, true)
	else _G.shell.text("Mounted new drive at " .. path, true) end
end

function compAdd(addr)
	for _, list in pairs{_G.gpu, _G.screen, _G.components} do
		for _, c in ipairs(list) do if c.address == addr then return end end
	end
	local type = comp_type(addr)
	local c = {address=addr, ctype=type}
	if type == "gpu" then table.insert(_G.gpu, c)
	elseif type == "screen" then table.insert(_G.screen, c)
	else
		_G.shell.text(type, true)
		if type == "filesystem" then mountFS(addr) end
		table.insert(_G.components, c)
	end
end

function compRemove(addr)
	local function remove(list)
		for i, c in ipairs(list) do
			if c.address == addr then table.remove(list, i); return c end
		end
	end
	local c = remove(_G.components)
	if c and c.ctype == "filesystem" then
		local path = "./mnt/"..addr:sub(1,8).."/"
		local ok, err = _G.filesystem.unmount(path)
		if not ok then _G.shell.text(err, true)
		else _G.shell.text("Unmounted drive at "..path, true) end
		if addr == _G.bootAddress then _G.shell.fault = 6 end
	end
	remove(_G.gpu); remove(_G.screen)
end

function dofile(file)
	_G.shell.text("=> "..file, true)
	local prog, err = loadfile(file)
	if prog then
		local ok, result = pcall(prog)
		if not ok then _G.shell.fault = 4 end
		return result
	else
		_G.shell.fault = 4
	end
end

function _G.shell.setScreenBuffer()
	local w, h = table.unpack(_G.wh)
	_G.screenbuffer = {}
	for i=1, w*h do _G.screenbuffer[i] = " " end
end

function _G.shell.wipeScreenBuffer()
	local w, h = table.unpack(_G.wh)
	for y=1,h do
		for x=1,w do
			_G.screenbuffer[(y-1)*w + x] = " "
		end
	end
end

function _G.shell.setColour(fg, bg)
	invoke(_G.bootgpu, "setForeground", fg)
	invoke(_G.bootgpu, "setBackground", bg)
end

function _G.shell.clear(x0, y0, x1, y1, str)
	invoke(_G.bootgpu, "fill", x0, y0, x1, y1, str)
	_G.shell.currentLine = 1
	_G.shell.wipeScreenBuffer()
end

function _G.shell.text(str, colour)
	local x, y = 1, _G.shell.currentLine + 1
	if colour then _G.shell.setColour(0xFFFFFF, 0x0000FF) end
	invoke(_G.bootgpu, "set", x, y, str)
	for i = 1, #str do
		_G.shell.writeChar(x + i - 1, y, str:sub(i, i))
	end
	_G.shell.currentLine = y
end

local function clamp(val, min, max) return math.max(min, math.min(max, val)) end

function _G.shell.writeChar(x, y, ch)
	local w, h = _G.wh[1], _G.wh[2]
	local i = (clamp(y,1,h)-1)*w + clamp(x,1,w)
	_G.screenbuffer[i] = ch
end

function _G.shell.readChar(x, y)
	local w, h = _G.wh[1], _G.wh[2]
	local i = (clamp(y,1,h)-1)*w + clamp(x,1,w)
	return _G.screenbuffer[i] or " "
end

function _G.shell.sleep(sec)
	local t = uptime() + sec
	repeat pullSignal(t - uptime()) until uptime() >= t
end

function _G.shell.panic()
	_G.shell.setColour(0xFFFFFF, 0xFF0000)
	_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
	for _, msg in ipairs{
		faults[_G.shell.fault],
		"Panic triggered.",
		"A crash dump is unavailable.",
		_G.shell.dump,
		"This system will shutdown in 5 seconds."
	} do _G.shell.text(msg, false) end
	_G.shell.sleep(5)
	computer.shutdown(false)
end

function _G.shell.run(path)
	local chunk, err = _G.filesystem.read(path, false)
	if not chunk then
		_G.shell.text("FATAL: CANNOT LOAD: " .. tostring(err), true)
		return false
	end
	assert(load(chunk))()
	return true
end

function clr() _G.shell.setColour(0x000000, 0x0000FF) end

function vital()
	_G.bootgpu, _G.bootscreen = comp_list("gpu")(), comp_list("screen")()
	invoke(_G.bootgpu, "bind", _G.bootscreen)
	_G.wh = {invoke(_G.bootgpu, "getResolution")}
	clr()
	_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
	_G.shell.setScreenBuffer()
end

function panicLowMem()
	if (totalMem() - freeMem()) / totalMem() >= 0.96 then
		_G.shell.fault = 2
		_G.shell.dump = "MEMORY USAGE TOO HIGH"
		_G.shell.panic()
	end
end

local ok = pcall(function() findComp(); vital() end)

if ok and _G.shell.fault == -1 then
	beep(1500, 0.1)
	_G.shell.text("Basic System Checks OK.", true)
	_G.shell.text("Please wait.", true)
	local success, msg = pcall(function()
		_G.shell.text("Loading Lib", true)
		_G.filesystem = dofile("/lib/filesystem.lua")
		mountFS(_G.bootAddress)
		_G.package.utility = dofile("/lib/utility.lua")
		_G.package.fileeditor = dofile("/lib/fileeditor.lua")
		_G.shell.text("Loading Kernel", true)
		_G.package.keyboard = dofile("/kernel/keyboard.lua")
		_G.package.command = dofile("/kernel/command.lua")
	end)

	if not success then
		_G.shell.fault = 4
		_G.shell.dump = msg
	else
		_G.shell.text("Finished Loading Software", true)
		_G.shell.sleep(1)
		_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
		_G.filesystem.directory = "./home/"
		_G.filesystem.read("./home/hello_world.txt", true)
		_G.package.utility.report()
		_G.shell.text("OK.", true)
		_G.shell.currentLine = _G.shell.currentLine + 1
	end

	while true do
		local e, addr, ascii, code, d = pullSignal(0.05)
		panicLowMem()
		if _G.shell.fault > -1 then return _G.shell.panic() end

		local ok, err = pcall(function()
			local char = ascii and string.char(ascii) or ""
			local kbd = _G.package.keyboard
			if kbd.status == 0 then kbd.update(e, code, char, ascii)
			else _G.package.fileeditor.update(e, code, char, ascii, d) end
		end)

		if e == "component_added" then compAdd(addr)
		elseif e == "component_removed" then compRemove(addr) end

		if not ok then
			_G.shell.fault = 5
			_G.shell.dump = err
			_G.shell.panic()
		end

		if _G.shell.currentLine >= _G.wh[2] then
			_G.shell.setColour(0xFFFFFF, 0x0000FF)
			_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
		end
		panicLowMem()
	end
else
	_G.shell.sleep(0.1)
	beep(500, 0.05) beep(500, 0.05) beep(500, 0.05)
	_G.shell.panic()
end
