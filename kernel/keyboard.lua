local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local flashOn = false
local K = 0
local originalChar = " "

keyboard.update = function(e, code)
    local gpu = _G.bootgpu
    local char = _G.shell.readChar(keyboard.x, keyboard.y) or " "

    if char ~= " " then
        originalChar = char
    end

    -- Flash every few ticks
    if K % 6 == 0 then
        local fg, bg = 0x000000, 0xFFFFFF
        if flashOn then
            fg, bg = 0xFFFFFF, 0x000000 -- Normal colors
        end

        _G.invoke(gpu, "setForeground", fg)
        _G.invoke(gpu, "setBackground", bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
        K = 0
    end

    K = K + 1
end

return keyboard
