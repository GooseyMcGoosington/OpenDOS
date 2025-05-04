local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local K = 0
local originalChar = " "
local lastX, lastY = 1, 2

keyboard.update = function(e, code)
    local gpu = _G.bootgpu

    -- Clamp to screen
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

    originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

    if K % 3 == 0 then
        -- Handle arrow key input IMMEDIATELY
        if code == 203 then
            keyboard.x = keyboard.x - 1
        elseif code == 205 then
            keyboard.x = keyboard.x + 1
        elseif code == 200 then
            keyboard.y = keyboard.y - 1
        elseif code == 208 then
            keyboard.y = keyboard.y + 1
        end
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        _G.invoke(gpu, "set", lastX, lastY, originalChar)
        lastX = keyboard.x
        lastY = keyboard.y

        local char = _G.shell.readChar(keyboard.x, keyboard.y)
        originalChar = char

        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        
    end
    K = K + 1
end

return keyboard
