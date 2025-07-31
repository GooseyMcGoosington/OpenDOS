local file_editor = {}
file_editor.active_dir = nil
file_editor.cursorX, file_editor.cursorY = 1, 1
file_editor.lineY = 1;
file_editor.maxWidth = 80
file_editor.buffer = { "" }

function file_editor.load(path, name)
    local filePath = path .. name
    file_editor.active_dir = filePath

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
    file_editor.read()
end

function file_editor.read()
    local bufferY = file_editor.lineY
    local yOffset = 0
    if _G.invoke then
        _G.shell.text("Invoke is available", true)
    else
        _G.shell.text("Invoke is NOT available", true)
    end
    for sY = bufferY, bufferY + 25 do
        local line = file_editor.buffer[sY] or ""
        local i = 1
        while i <= #line do
            for x = 1, 80 do
                local char = line:sub(i, i)
                if char == "" then break end


                _G.invoke(_G.bootgpu, "set", x, sY + yOffset, char)
                i = i + 1
            end
            yOffset = yOffset + 1
        end
    end
end

function file_editor.update(e, code, char, ascii)
    if not active_dir then return end
    _G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
end

return file_editor