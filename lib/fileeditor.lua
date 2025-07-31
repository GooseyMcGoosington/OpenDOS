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
    _G.shell.clear(0, 0, _G.wh[1], _G.wh[2], " ")
    local bufferY = file_editor.lineY
    local yOffset = 0
    for sY = bufferY, bufferY + 25 do
        local line = file_editor.buffer[sY] or ""
        local i = 1
        local x = 1
        while i <= #line do
            local char = line:sub(i, i)
            _G.invoke(_G.bootgpu, "set", x, sY + yOffset, char)
            i = i + 1
            x = x + 1
            if x > 80 then
                x = 1
                yOffset = yOffset + 1
            end
        end
        sY = sY + 1
    end
end

function file_editor.update(e, code, char, ascii, d)
    _G.shell.text(e, true)
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
    end
end

return file_editor