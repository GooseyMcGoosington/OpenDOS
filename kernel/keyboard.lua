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
        local w = _G.wh[1]
        for x = 1, w do
            local idx = (y - 1) * w + x
            str = str .. _G.screenbuffer[idx]
        end
        cLine_string = str
    end)
end

-- Main update function: handle movement and writing
function keyboard.update(e, code, char, ascii)
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
    -- be able to write to the screen buffer
    if char and e == "key_down" then
        if code == 28 then
            -- enter
            keyboard.getLineAsString()
            --_G.shell.text("WORD => "..cLine_string, true)
            _G.package.command.parse(cLine_string)
            _G.shell.currentLine = _G.shell.currentLine + 1
            keyboard.x = 1
            return
        end
        if ascii >= 32 and ascii <= 126 then
            -- Write character at current cursor
            _G.shell.setColour(0xFFFFFF, 0x0000FF) -- white text, blue bg
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
            
            -- Update internal screenbuffer if needed
            if _G.screenbuffer then
                local idx = (keyboard.y - 1) * _G.wh[1] + keyboard.x
                _G.screenbuffer[idx] = char
            end
            -- Move cursor right
            keyboard.x = keyboard.x + 1
            lastX = keyboard.x
            lastY = keyboard.y
        
            -- Optional: draw a visual cursor at the new position (like an underscore or inverse space)
            _G.clr()
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, "_")  -- use "_" or a space for cursor
        end
    end
    K = K + 1
end

return keyboard
