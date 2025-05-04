local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local flashOn = false
local K = 0

local prevX, prevY = keyboard.x, keyboard.y
local originalChar = " "
local originalFg, originalBg = 0xFFFFFF, 0x0000FF

keyboard.update = function(e, code)
    local gpu = _G.bootgpu

    if K % 3 == 0 then
        -- Restore previous cell
        if flashOn then
            _G.shell.setColour(0xFFFFFF, 0x0000FF)
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

        -- Store current state
        prevX, prevY = keyboard.x, keyboard.y
        originalChar = _G.shell.readChar(keyboard.x, keyboard.y) or " "
        originalFg, originalBg = _G.shell.getColour()

        -- Draw cursor
        local fg, bg = 0x0000FF, 0xFFFFFF
        if flashOn then
            fg, bg = 0xFFFFFF, 0x0000FF
        end
        _G.shell.setColour(fg, bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
        K = 0
    end

    K = K + 1
end

return keyboard
