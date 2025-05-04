local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local K = 0
local originalChar = " "
local lastX, lastY = 1, 2
keyboard.locked = true -- true means it can only write to the line, false means it can move about freely

local cLine_string = ""

keyboard.update = function(e, code, char)
    local gpu = _G.bootgpu

    -- Clamp to screen
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

    originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

    if e == "key_down" then
        -- Handle movement
        if K % 3 == 0 then
            if code == 203 then -- Left arrow
                keyboard.x = keyboard.x - 1
            elseif code == 205 then -- Right arrow
                keyboard.x = keyboard.x + 1
            end
            if not keyboard.locked then
                if code == 200 then -- Up
                    keyboard.y = keyboard.y - 1
                elseif code == 208 then -- Down
                    keyboard.y = keyboard.y + 1
                end
            else
                keyboard.y = _G.shell.currentLine
            end
        end

        -- Handle typing (printable ASCII)
        if char and #char == 1 and string.byte(char) >= 32 and string.byte(char) <= 126 then
            if keyboard.locked then
                keyboard.y = _G.shell.currentLine
            end
            _G.shell.writeChar(keyboard.x, keyboard.y, char)
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
            keyboard.x = math.min(keyboard.x + 1, _G.wh[1]) -- Move cursor right
            keyboard.getLineAsString()
        end
    end

    -- Update cursor
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", lastX, lastY, originalChar)
    lastX = keyboard.x
    lastY = keyboard.y

    local charAtCursor = _G.shell.readChar(keyboard.x, keyboard.y)
    originalChar = charAtCursor

    _G.shell.setColour(0x000000, 0xFFFFFF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, charAtCursor)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)

    K = K + 1
end


keyboard.getLineAsString = function()
    pcall(function()
        local str = ""
        local y = _G.shell.currentLine
        for x = 1, _G.wh[1] do
            str = str.._G.screenbuffer[x][y]
        end
        cLine_string = str
    end)
end
return keyboard
