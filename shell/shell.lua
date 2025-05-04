local invoke=component.invoke

_G.gpu = {}
_G.screen = {}
_G.components = {}
_G.bootscreen = nil
_G.bootgpu = nil
_G.shell = {currentLine=1,fault=-1} -- set to 0 for testing
_G.wh = {0,0}
_G.bootAddress=computer.getBootAddress()
_G.invoke=component.invoke
_G.filesystem = nil
_G.screenbuffer={}

local faultCodes = {
	[0] = "FATAL: Vital Fault",
	[1] = "FATAL: System Fault",
	[2] = "FATAL: Out of Memory",
	[3] = "FATAL: Hardware Fault",
	[4] = "SYSTEM: Software Load Failure"
}

local shutdown = computer.shutdown
computer.shutdown = function(reboot)
	if os.sleep then
		computer.pushSignal("shutdown")
		os.sleep(0.1)
	end
	shutdown(reboot)
end

function findComp()
	for address, ctype in component.list() do
		if ctype == "gpu" then
			table.insert(_G.gpu, {address=address})
		elseif ctype == "screen" then
			table.insert(_G.screen, {address=address})
		else
			table.insert(_G.components, {address=address})
		end
	end
end

local loadfile = ...

function dofile(file)
	_G.shell.text("=> "..file, true)
	local program, reason = loadfile(file)
	if program then
		local result = table.pack(pcall(program))
		if result[1] then
			return table.unpack(result, 2, result.n)
		else
			_G.shell.fault = 4
		end
	else
		_G.shell.fault = 4
	end
end

function _G.shell.setScreenBuffer()
	for x = 1, _G.wh[1] do
		for y = 1, _G.wh[2] do
			table.insert(_G.screenbuffer, 0)
		end
	end
end

function _G.shell.setColour(x, y)
	local gpu = _G.bootgpu
	invoke(gpu, "setForeground", x)
	invoke(gpu, "setBackground", y)
end
function _G.shell.clear(x0, y0, x1, y1, str)
	invoke(_G.bootgpu, "fill", x0, y0, x1, y1, str)	
	_G.shell.currentLine=1 -- Return to 1
end
--[[function _G.shell.text(str, setColour)
	if setColour then
		_G.shell.setColour(0xFFFFFF, 0x0000FF)
		invoke(_G.bootgpu, "set", 1, _G.shell.currentLine + 1, str)	
		clr()
		_G.shell.currentLine = _G.shell.currentLine + 1
	else
		invoke(_G.bootgpu, "set", 1, _G.shell.currentLine + 1, str)	
		_G.shell.currentLine = _G.shell.currentLine + 1
	end
end]]
function _G.shell.text(str, setColour)
	local x = 1
	local y = _G.shell.currentLine + 1
	if setColour then
		_G.shell.setColour(0xFFFFFF, 0x0000FF)
	end
	invoke(_G.bootgpu, "set", x, y, str)
	for i = 1, #str do
		_G.shell.writeChar(x + i - 1, y, str:sub(i, i))
	end
	_G.shell.currentLine = y
end  
function _G.shell.writeChar(x, y, char)
	local w = _G.wh[1]
	local index = (y - 1) * w + x
	_G.screenbuffer[index] = char
end
function _G.shell.sleep(seconds)
	local deadline = computer.uptime() + seconds
	repeat
	  local now = computer.uptime()
	  computer.pullSignal(deadline - now)
	until computer.uptime() >= deadline
  end
function _G.shell.panic()
	_G.shell.setColour(0xFFFFFF, 0xFF0000)
	_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
	_G.shell.text(faultCodes[_G.shell.fault], false)
	_G.shell.text("This system will shutdown in 5 seconds.", false)
	_G.shell.sleep(5)
	computer.shutdown(false)
end
function clr()
	_G.shell.setColour(0x000000, 0x0000FF)
end
function vital()
	_G.bootgpu = component.list("gpu")() -- get the first GPU available
	_G.bootscreen = component.list("screen")() -- get the first screen available
	invoke(_G.bootgpu, "bind", _G.bootscreen)

	local w, h = invoke(_G.bootgpu, "getResolution")
	_G.wh = {w,h}
	clr()
	_G.shell.clear(1, 1, w, h, " ")
	_G.shell.setScreenBuffer()
end
local success, _ = pcall(function()
	findComp()
	vital()
end)
if success and _G.shell.fault == -1 then
	computer.beep(1500, 0.1)
	--_G.shell.text("Basic System Checks OK.", true)
	--_G.shell.text("Please wait.", true)
	local success, _ = pcall(function()
		_G.shell.text("Loading Lib", true)
		_G.filesystem = dofile("/lib/filesystem.lua")
	end)
	if not success then
		_G.shell.fault = 4
	else
		--_G.shell.text("Finished Loading Software", true)
		--_G.shell.sleep(1)
		--_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
		--_G.filesystem.directory = "./home" -- lists current directory
		--_G.shell.text("Current Directory: ".._G.filesystem.directory, true)
		--_G.filesystem.list(_G.filesystem.directory)
		--_G.filesystem.read(_G.filesystem.directory.."/hello_world.txt", true)
		--[[_G.shell.text(tostring(_G.filesystem.exists("shell/")), true)
		_G.shell.text(tostring(_G.filesystem.isDirectory("shell/")), true)
		_G.shell.text(tostring(_G.filesystem.size("shell/shell.lua")), true)]]
	end
	-- later I want to use the highest tier graphics card
	while true do
		local e, _, _, code = computer.pullSignal()
		if _G.shell.fault > -1 then
			_G.shell.panic()
			break
		end
	end
else
	_G.shell.sleep(0.1)
	computer.beep(500, 0.05)
	computer.beep(500, 0.05)
	computer.beep(500, 0.05)
	-- Panic
	_G.shell.panic()
end