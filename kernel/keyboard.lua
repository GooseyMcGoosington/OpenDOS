local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local flashOn = false
local K = 0

local prevX, prevY = keyboard.x, keyboard.y
local originalChar = _G.shell.readChar(keyboard.x, keyboard.y) or " "

keyboard.update = function(e, code)
    local gpu = _G.bootgpu

    if K % 3 == 0 then
        -- Always restore previous cell
        _G.shell.setColour(0xFFFFFF, 0x0000FF) -- White on blue
        _G.invoke(gpu, "set", prevX, prevY, originalChar)

        -- Handle arrow keys
        if code == 203 then
            keyboard.x = keyboard.x - 1
        elseif code == 205 then
            keyboard.x = keyboard.x + 1
        elseif code == 200 then
            keyboard.y = keyboard.y - 1
        elseif code == 208 then
            keyboard.y = keyboard.y + 1
        end

        -- Clamp to screen
        keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
        keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

        -- Update state
        prevX, prevY = keyboard.x, keyboard.y
        originalChar = _G.shell.readChar(keyboard.x, keyboard.y) or " "

        -- Draw cursor with flashing effect
        local fg, bg
        if flashOn then
            fg, bg = 0x000000, 0xFFFFFF -- Black on white (flash)
        else
            fg, bg = 0xFFFFFF, 0x0000FF -- White on blue (normal)
        end
        _G.shell.setColour(fg, bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
        K = 0
    end

    K = K + 1
end

return keyboard
