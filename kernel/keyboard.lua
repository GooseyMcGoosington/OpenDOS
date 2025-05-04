local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local flashOn = false
local K = 0

local prevX, prevY = keyboard.x, keyboard.y
local originalChar = " "

keyboard.update = function(e, code)
    local gpu = _G.bootgpu

    if K % 3 == 0 then
        -- Restore previous cell
        if flashOn then
            _G.shell.setColour(0xFFFFFF, 0x0000FF) -- White text on blue bg
            _G.invoke(gpu, "set", prevX, prevY, originalChar)
        end

        -- Handle arrow key input
        if code == 203 then
            keyboard.x = keyboard.x - 1
        elseif code == 205 then
            keyboard.x = keyboard.x + 1
        elseif code == 200 then
            keyboard.y = keyboard.y - 1
        elseif code == 208 then
            keyboard.y = keyboard.y + 1
        end

        -- Clamp within screen bounds
        keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
        keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

        -- Store current position and character
        prevX, prevY = keyboard.x, keyboard.y
        originalChar = _G.shell.readChar(keyboard.x, keyboard.y) or " "

        -- Flashing cursor logic
        local fg, bg
        if flashOn then
            fg, bg = 0x000000, 0xFFFFFF -- Black text on white
        else
            fg, bg = 0xFFFFFF, 0x0000FF -- White text on blue
        end

        _G.shell.setColour(fg, bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
        K = 0
    end

    K = K + 1
end

return keyboard
