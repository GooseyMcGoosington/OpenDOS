local file_editor = {}
file_editor.active_dir = nil
file_editor.cursorX, file_editor.cursorY = 1, 1
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

        for i, line in ipairs(file_editor.buffer) do
            _G.shell.text(line, true)
        end
    end)
    if not success then
        _G.shell.text(err, true)
        _G.package.keyboard.status = 0
    end
end

function file_editor.update(e, code, char, ascii)
    if not active_dir then return end
    _G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
end

return file_editor