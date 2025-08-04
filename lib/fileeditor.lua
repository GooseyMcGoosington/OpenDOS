local file_editor = {}
file_editor.active_dir = nil
file_editor.cursorX, file_editor.cursorY = 1, 2
file_editor.lineY = 1;
file_editor.maxWidth = 80
file_editor.buffer = { "" }

local originalChar = nil
local cX, cY = 1, 2
local lastX, lastY = 1, 2
local K = 0

function file_editor.load(path, name)
    local filePath = path .. name
    file_editor.active_dir = filePath
    local oldCX = file_editor.cursorX
    local oldCY = file_editor.cursorY
    local success, err = pcall(function()
        local str = _G.filesystem.read(file_editor.active_dir, false)
            for i = 1, #str do
            local c = str:sub(i, i)
            if c == "\n" then
                file_editor.cursorY = file_editor.cursorY + 1
                file_editor.cursorX = 1
                table.insert(file_editor.buffer, "")
            else
                file_editor.buffer[file_editor.cursorY] = file_editor.buffer[file_editor.cursorY] .. c
                file_editor.cursorX = file_editor.cursorX + 1

                if file_editor.cursorX > file_editor.maxWidth then
                    file_editor.cursorY = file_editor.cursorY + 1
                    file_editor.cursorX = 1
                    table.insert(file_editor.buffer, "")
                end
            end
        end
    end)
    if not success then
        _G.shell.text(err, true)
        _G.package.keyboard.status = 0
    end
    file_editor.cursorX = oldCX
    file_editor.cursorY = oldCY
    file_editor.read()
end

function file_editor.read()
    _G.shell.clear(0, 0, _G.wh[1], _G.wh[2], " ")
    local bufferY = file_editor.lineY
    local yOffset = 0
    for sY = bufferY, bufferY + 25 do
        local line = file_editor.buffer[sY] or ""
        local i = 1
        local x = 1
        _G.invoke(_G.bootgpu, "set", x, sY-bufferY, line)
        sY = sY + 1
    end
end

function file_editor.update(e, code, char, ascii, d)
    
    if e == "scroll" then
        local direction = d
        if (direction > 0) then
            file_editor.lineY = file_editor.lineY - 1
        elseif (direction < 0) then
            file_editor.lineY = file_editor.lineY + 1
        end
        if file_editor.lineY < 1 then
            file_editor.lineY = 1
        end
        file_editor.read()
    end
    originalChar = _G.shell.readChar(cX, cY)
    if K % 3 == 0 then

        _G.shell.setColour(0xFFFFFF, 0x0000FF)
        _G.invoke(gpu, "set", lastX, lastY, originalChar)
        lastX = cX
        lastY = cY
        --[[local screenChar = _G.shell.readChar(file_editor.cursorX, file_editor.cursorY)
        originalChar = screenChar
        _G.shell.setColour(0x000000, 0xFFFFFF)
        _G.invoke(gpu, "set", file_editor.cursorX, file_editor.cursorY, screenChar)
        _G.shell.setColour(0xFFFFFF, 0x0000FF)]]
    end
    K = K +1
end

return file_editor