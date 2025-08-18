local eeprom = component.list("eeprom")()
local component = _G.component
local computer  = _G.computer
local fsAddress = component.list("filesystem")()
local fs = component.proxy(fsAddress)

local dsl = 1

local dsk={}
local boot={}

local inv=component.invoke
computer.getBootAddress = function()
	return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
	return boot_invoke(eeprom, "setData", address)
end

function boot_invoke(address, method, ...)
  return component.invoke(address, method, ...)
end

local function fMem(mem)
	local units = {"B", "KiB", "MiB", "GiB"}
	local unit = 1
	while mem > 1024 and units[unit] do
		unit = unit + 1
		mem = mem/1024
	end
	return mem.." "..units[unit]
end

local function isBootable(a)
	if inv(a, "exists", "/init.lua") then
		return true
	end
	return false
end
for d, v in pairs(component.list("filesystem")) do
	table.insert(dsk, d)
end
for _, addr in pairs(dsk) do
  local fs = component.proxy(addr)
  if isBootable(addr) then
    table.insert(boot, addr)
  end
end

local screen = component.list("screen")()
local gpu = component.list("gpu")()
inv(gpu, "bind", screen)
inv(gpu, "setResolution", inv(gpu, "maxResolution"))
local w, h = inv(gpu, "getResolution")
local function clr()
	inv(gpu, "setForeground", 0xFFFFFF)
	inv(gpu, "setBackground", 0x000000)
	inv(gpu, "fill", 1, 1, w, h, " ")	
end
local w2 = w/2
local function txt(text, y)
	local x = w2-#text/2
	inv(gpu, "set", x, y, text)
end

local function setClr(x, y)
	inv(gpu, "setForeground", x)
	inv(gpu, "setBackground", y)
end

local function isFloppy(a)
	local fs = component.proxy(a)
	if not fs.spaceTotal or not fs.isReadOnly then
		return false
	end
	local total = fs.spaceTotal()
	local readonly = fs.isReadOnly()
	return (total <= 1024 * 1024 and readonly)
end

local function dMu()
	setClr(0xFFFFFF, 0x000000)
	txt("BOOT MENU", 2)
	txt("SELECT DISK", 3)
	txt("BOOTABLE DISKS: " .. #boot, 4)
	txt(fMem(computer.totalMemory()).." FREE", 5)

	for i, a in pairs(boot) do
		if i == dsl then
			setClr(0xFFFFFF, 0x000000)
		else
			setClr(0xFFFFFF, 0x000000)
		end
		local raw = component.type(a)
		local diskType = "DISK"
		if isFloppy(a) then
			diskType = "FLOPPY"
		end
		txt(diskType.." (" .. i .. "): "..a, 7+i)
	end
end

local function bootload(a)
  clr()
  txt("BOOTING FROM "..a, 2)
  computer.setBootAddress(a)
  local fs = component.proxy(a)
  local handle, reason = fs.open("/init.lua")
  if not handle then
    txt("BOOTSTRAPPER FAULT: " .. tostring(reason), 4)
    return
  end
  local content = ""
  repeat
    local chunk = fs.read(handle, math.huge)
    content = content .. (chunk or "")
  until not chunk
  fs.close(handle)
  local result, err = load(content, "=init.lua", "t", _G)
  if not result then
    txt("DISK ERROR: " .. tostring(err), 5)
    return
  end
  result()
end


clr()
dMu()

while true do
	local e, _, _, code = computer.pullSignal()
	if e == "key_down" then
        if code == 208 then
            dsl = dsl + 1
            if dsl > #boot then
                dsl = 1
            end
        elseif code == 200 then
            dsl = dsl - 1
            if dsl < 1 then
                dsl = #boot
            end
        elseif code == 28 then
            bootload(boot[dsl])
        end
		dMu()
	end
end