local keyboard = {}
keyboard.x = 1
keyboard.y = 2
local K = 0
local originalChar = " "
local lastX, lastY = 1, 2
keyboard.locked = true
local cLine_string = ""
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
function keyboard.update(e, code, char, ascii)
    local gpu = _G.bootgpu
    if e == "key_down" and code == 28 then
        keyboard.getLineAsString()
        _G.package.command.parse(cLine_string)
        _G.shell.currentLine = _G.shell.currentLine + 1
        keyboard.y = _G.shell.currentLine
        keyboard.x = 1
        return
    end
    if e == "key_down" and code == 14 then
        if keyboard.x > 1 then
            lastX = keyboard.x
            lastY = keyboard.y
            keyboard.x = keyboard.x - 1
            local idx = (keyboard.y - 1) * _G.wh[1] + keyboard.x
            _G.screenbuffer[idx] = " "
            _G.shell.setColour(0xFFFFFF, 0x0000FF)
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, " ")
            return
        end
    end
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))
    originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)

    if K % 3 == 0 then
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
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        _G.invoke(gpu, "set", lastX, lastY, originalChar)
        lastX = keyboard.x
        lastY = keyboard.y
        local screenChar = _G.shell.readChar(keyboard.x, keyboard.y)
        originalChar = screenChar
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, screenChar)
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
    end
    -- be able to write to the screen buffer
    if char and e == "key_down" then
        if ascii >= 32 and ascii <= 126 then
            _G.shell.setColour(0xFFFFFF, 0x0000FF)
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
            if _G.screenbuffer then
                local idx = (keyboard.y - 1) * _G.wh[1] + keyboard.x
                _G.screenbuffer[idx] = char
            end
            keyboard.x = keyboard.x + 1
            lastX = keyboard.x
            lastY = keyboard.y
            _G.clr()
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, "_")
        end
    end
    K = K + 1
end

return keyboard
