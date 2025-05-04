local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local flashOn = false
local K = 0

local prevX, prevY = keyboard.x, keyboard.y
local originalChar = " "

keyboard.update = function(e, code)
    local gpu = _G.bootgpu

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

    -- Clamp to screen
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

    -- If cursor moved, restore old cell and read new one
    if prevX ~= keyboard.x or prevY ~= keyboard.y then
        -- Restore previous
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        _G.invoke(gpu, "set", prevX, prevY, originalChar)

        -- Update new
        prevX, prevY = keyboard.x, keyboard.y
        originalChar = _G.shell.readChar(keyboard.x, keyboard.y) or " "
    end

    -- Blink every 3 frames
    if K % 3 == 0 then
        local fg, bg
        if flashOn then
            fg, bg = 0x000000, 0xFFFFFF -- Flash: black on white
        else
            fg, bg = 0xFFFFFF, 0x0000FF -- Normal: white on blue
        end

        _G.shell.setColour(fg, bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
    end

    K = K + 1
end

return keyboard
