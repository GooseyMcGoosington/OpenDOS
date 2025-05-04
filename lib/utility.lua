local utility = {}

utility.fMem = function(mem)
	local units = {"B", "KiB", "MiB", "GiB"}
	local unit = 1
	while mem > 1024 and units[unit] do
		unit = unit + 1
		mem = mem/1024
	end
	return mem.." "..units[unit]
end

utility.report = function()
    _G.shell.text(_G.package.utility.fMem(computer.freeMemory()) .. " OUT OF " .. _G.package.utility.fMem(computer.totalMemory()) .. " FREE", true)
    _G.shell.text("GPUS: " .. tostring(#_G.gpu), true)
    _G.shell.text("SCREENS: " .. tostring(#_G.screen), true)
    _G.shell.text("TOTAL COMPONENTS: " .. tostring(#_G.components), true)
    _G.shell.text("SCREEN RESOLUTION: " .. tostring(_G.wh[1]) .. "x" .. tostring(_G.wh[2]), true)
    _G.shell.text("KERNEL VERSION: 1.0.0", true)
    _G.shell.text(tostring(#_G.package).." LOADED PACKAGES", true)
end

return utility