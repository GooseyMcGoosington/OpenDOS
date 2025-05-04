local keyboard = {}

keyboard.x = 1
keyboard.y = 2
local originalChar = " "
local lastX, lastY = 1, 2
keyboard.locked = true -- true: remain on current input line, false: free movement

local cLine_string = ""

-- Capture the current shell line into cLine_string
function keyboard.getLineAsString()
    pcall(function()
        local str = ""
        local y = _G.shell.currentLine
        for x = 1, _G.wh[1] do
            str = str .. (_G.screenbuffer[x][y] or " ")
        end
        cLine_string = str
    end)
end

-- Highlight a cell at (x,y) with inverted colors
local function highlight(x, y)
    local ch = _G.shell.readChar(x, y)
    _G.shell.setColour(0x000000, 0xFFFFFF)
    _G.invoke(_G.bootgpu, "set", x, y, ch)
    return ch
end

-- Restore a cell at (x,y) to its original character and colors
local function restore(x, y, ch)
    _G.shell.setColour(0xFFFFFF, 0x0000FF)
    _G.invoke(_G.bootgpu, "set", x, y, ch)
end

-- Main update: handle arrows and ASCII input
function keyboard.update(e, code, ascii)
    -- Movement: arrow keys
    if code == 203 or code == 205 or code == 200 or code == 208 then
        -- Clear previous highlight
        restore(lastX, lastY, originalChar)

        -- Compute new position
        if code == 203 then keyboard.x = keyboard.x - 1
        elseif code == 205 then keyboard.x = keyboard.x + 1 end
        if not keyboard.locked then
            if code == 200 then keyboard.y = keyboard.y - 1
            elseif code == 208 then keyboard.y = keyboard.y + 1 end
        else
            keyboard.y = _G.shell.currentLine
        end

        -- Clamp
        keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
        keyboard.y = math.max(1, math.min(keyboard.y, _G.wh[2]))

        -- Highlight new position and store state
        originalChar = highlight(keyboard.x, keyboard.y)
        lastX, lastY = keyboard.x, keyboard.y

    -- ASCII input: single character strings
    elseif ascii and #ascii == 1 then
        -- Restore highlight area before writing
        restore(keyboard.x, keyboard.y, originalChar)

        -- Write the character
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(_G.bootgpu, "set", keyboard.x, keyboard.y, ascii)
        if _G.screenbuffer then _G.screenbuffer[keyboard.x][keyboard.y] = ascii end

        -- Move cursor right and update line string
        keyboard.x = keyboard.x + 1
        keyboard.getLineAsString()

        -- Clamp
        keyboard.x = math.max(1, math.min(keyboard.x, _G.wh[1]))
        keyboard.y = _G.shell.currentLine

        -- Highlight new cursor
        originalChar = highlight(keyboard.x, keyboard.y)
        lastX, lastY = keyboard.x, keyboard.y
    end
end

return keyboard