local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local K = 0
local originalChar = " "
local lastX, lastY = 1, 2
keyboard.locked = true -- true means it can only write to the line, false means it can move about freely

local cLine_string = ""

-- Helper to redraw a cell at last cursor position
local function restoreLast(gpu)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", lastX, lastY, originalChar)
end

keyboard.update = function(e, code, ascii)
    local gpu = _G.bootgpu

    -- Clamp to screen
    keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
    keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

    -- Restore previous character under cursor
    originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)
    
    if K % 3 == 0 then
        -- Handle arrow or typing input
        if ascii and ascii >= 32 and ascii <= 126 then
            -- Printable character: write at current cursor
            local char = string.char(ascii)
            -- Draw the character
            _G.shell.setColour(0x000000, 0xFFFFFF)
            _G.invoke(gpu, "set", keyboard.x, keyboard.y, char)
            -- Advance cursor
            keyboard.x = keyboard.x + 1
            -- Keep on same line if locked
            if keyboard.locked then
                keyboard.y = _G.shell.currentLine
            end
        else
            -- Handle arrow movement
            if code == 203 then -- left arrow
                keyboard.x = keyboard.x - 1
            elseif code == 205 then -- right arrow
                keyboard.x = keyboard.x + 1
            end
            if not keyboard.locked then
                if code == 200 then -- up arrow
                    keyboard.y = keyboard.y - 1
                elseif code == 208 then -- down arrow
                    keyboard.y = keyboard.y + 1
                end
            else
                -- Locked: stay on current line
                keyboard.y = _G.shell.currentLine 
            end
        end

        -- Restore last cell and update lastX/lastY
        restoreLast(gpu)
        lastX = keyboard.x
        lastY = keyboard.y

        -- Read and highlight new cell
        originalChar = _G.shell.readChar(keyboard.x, keyboard.y)
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", keyboard.x, keyboard.y, originalChar)
        _G.shell.setColour(0xFFFFFF, 0x0000FF)
    end

    K = K + 1
end

keyboard.getLineAsString = function()
    pcall(function()
        local str = ""
        local y = _G.shell.currentLine
        for x = 1, _G.wh[1] do
            str = str .. _G.screenbuffer[x][y]
        end
        cLine_string = str
    end)
end

return keyboard
