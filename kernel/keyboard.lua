local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local K = 0
local originalChar = " "
local lastX, lastY = 1, 2
keyboard.locked = true -- true means it can only write to the line, false means it can move about freely

local cLine_string = ""

-- Utility to capture the current line as string
function keyboard.getLineAsString()
    pcall(function()
        local str = ""
        local y = _G.shell.currentLine
        for x = 1, _G.wh[1] do
            str = str .. _G.screenbuffer[x][y]
        end
        cLine_string = str
    end)
end

-- Main update function: handle movement and writing
function keyboard.update(e, code, ascii)
    local gpu = _G.bootgpu

    -- Clamp cursor to screen
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

    -- Restore previous character highlight
    originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

    if K % 3 == 0 then
        -- Arrow key movement
        if code == 203 then
            keyboard.x = keyboard.x - 1
        elseif code == 205 then
            keyboard.x = keyboard.x + 1
        end
        if not keyboard.locked then
            if code == 200 then
                keyboard.y = keyboard.y - 1
            elseif code == 208 then
                keyboard.y = keyboard.y + 1
            end
        else
            -- Stay on current input line
            keyboard.y = _G.shell.currentLine
        end

        -- Restore last position
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        _G.invoke(gpu, "set", lastX, lastY, originalChar)
        lastX = keyboard.x
        lastY = keyboard.y

        -- Highlight new position
        local char = _G.shell.readChar(keyboard.x, keyboard.y)
        originalChar = char
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
    end

    -- Character input handling: write ascii to screenbuffer
    if ascii and #ascii == 1 then
        -- Write character at current cursor
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, ascii)
        -- Update internal screenbuffer if needed
        if _G.screenbuffer then
            _G.screenbuffer[keyboard.x][keyboard.y] = ascii
        end
        -- Move cursor right
        keyboard.x = keyboard.x + 1
        -- Capture updated line string
        keyboard.getLineAsString()
        -- Restore highlight on new cursor
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        local nextChar = _G.shell.readChar(keyboard.x, keyboard.y)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, nextChar)
    end

    K = K + 1
end

return keyboard
