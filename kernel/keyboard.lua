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
    if K % 3 == 0 then
        local fg, bg = 0x000000, 0xFFFFFF
        if flashOn then
            fg, bg = 0xFFFFFF, 0x0000FF -- Normal colors
        end
        _G.shell.setColour(fg, bg)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

        flashOn = not flashOn
        K = 0

        if code == 203 then
            keyboard.x = keyboard.x - 1
        end
        if code == 205 then
            keyboard.x = keyboard.x + 1
        end
        if code == 200 then
            keyboard.y = keyboard.y - 1
        end
        if code == 208 then
            keyboard.y = keyboard.y + 1
        end
        if keyboard.x < 1 then
            keyboard.x = 1
        elseif keyboard.x > _G.wh[1] then
            keyboard.x = _G.wh[1]
        end
        if keyboard.y < 1 then
            keyboard.y = 1
        elseif keyboard.y > _G.wh[2] then
            keyboard.y = _G.wh[2]
        end
    end

    K = K + 1
end

return keyboard
