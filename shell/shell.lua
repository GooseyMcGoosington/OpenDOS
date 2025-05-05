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
_G.package = {
	keyboard=nil,
	command=nil,
	utility=nil
}
_G.screenbuffer={}
local faultCodes = {
	[0] = "FATAL: Vital Fault",
	[1] = "FATAL: System Fault",
	[2] = "FATAL: Out of Memory",
	[3] = "FATAL: Hardware Fault",
	[4] = "SYSTEM: Software Load Failure",
	[5] = "KERNEL: Software Exception"
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
	local width, height = _G.wh[1], _G.wh[2]
	_G.screenbuffer = {} -- Reset the buffer
	for i = 1, width * height do
		_G.screenbuffer[i] = " "
	end
end
function _G.shell.wipeScreenBuffer()
	for x = 1, _G.wh[1] do
		for y = 1, _G.wh[2] do
			local idx = (y - 1) * _G.wh[1] + x
			_G.screenbuffer[idx] = " "
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
	_G.shell.wipeScreenBuffer()
end
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
	local h = _G.wh[2]

	if x < 1 then
		x = 1
	end
	if x > w then
		x = w
	end
	if y < 1 then
		y = 1
	end
	if y > h then
		y = h
	end
	local index = (y - 1) * w + x
	_G.screenbuffer[index] = char
end
function _G.shell.readChar(x, y)
	local w = _G.wh[1]
	local h = _G.wh[2]

	if x < 1 then
		x = 1
	end
	if x > w then
		x = w
	end
	if y < 1 then
		y = 1
	end
	if y > h then
		y = h
	end
	local index = (y - 1) * w + x
	return _G.screenbuffer[index] or " "
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
	_G.shell.text("Panic triggered to prevent system damage.", false)
	_G.shell.text("Crash Dump will be located in ./home", false)
	_G.shell.text("This system will shutdown in 5 seconds.", false)
	_G.shell.sleep(5)
	computer.shutdown(false)
end
function _G.shell.run(path, ...)
    local chunk, err = _G.filesystem.read(path, false)
    if not chunk then
        _G.shell.text("FATAL: CANNOT LOAD " .. ": " .. tostring(err), true)
        return false
    end
	local program = assert(load(chunk))()
    return true, result
end

function clr()
	_G.shell.setColour(0x000000, 0x0000FF)
end
function vital()
	_G.bootgpu = component.list("gpu")()
	_G.bootscreen = component.list("screen")()
	invoke(_G.bootgpu, "bind", _G.bootscreen)

	local w, h = invoke(_G.bootgpu, "getResolution")
	_G.wh = {w,h}
	clr()
	_G.shell.clear(1, 1, w, h, " ")
	_G.shell.setScreenBuffer()
end
function panicLowMem()
	local used = (computer.totalMemory() - computer.freeMemory()) / computer.totalMemory()
	if used >= 0.93 then
		_G.shell.fault = 2
		_G.shell.panic()
		collectgarbage()
	end
end
local success, _ = pcall(function()
	findComp()
	vital()
end)
if success and _G.shell.fault == -1 then
	computer.beep(1500, 0.1)
	_G.shell.text("Basic System Checks OK.", true)
	_G.shell.text("Please wait.", true)
	local success, _ = pcall(function()
		_G.shell.text("Loading Lib", true)
		_G.filesystem = dofile("/lib/filesystem.lua")
		_G.package.utility = dofile("/lib/utility.lua")
		_G.shell.text("Loading Kernel", true)
		_G.package.keyboard = dofile("/kernel/keyboard.lua")
		_G.package.command = dofile("/kernel/command.lua")
	end)
	if not success then
		_G.shell.fault = 4
	else
		_G.shell.text("Finished Loading Software", true)
		_G.shell.sleep(1)
		_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
		_G.filesystem.directory = "./home"
		_G.filesystem.read(_G.filesystem.directory.."/hello_world.txt", true)
		_G.package.utility.report()
		_G.shell.text("OK.", true)

		_G.shell.currentLine = _G.shell.currentLine + 1
	end
	-- later I want to use the highest tier graphics card
	while true do
		local e, _, ascii, code = computer.pullSignal(0.05)
		panicLowMem()
		if _G.shell.fault > -1 then
			_G.shell.panic()
			return
		end
		local success, msg = pcall(function()
			local char = ascii ~= nil
			if char then
				char = string.char(ascii)
			else
				char = ""
			end
			_G.package.keyboard.update(e, code, char, ascii)
		end)
		if not success then
			_G.shell.fault = 5
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
	computer.beep(500, 0.05)
	computer.beep(500, 0.05)
	computer.beep(500, 0.05)
	-- Panic
	_G.shell.panic()
end