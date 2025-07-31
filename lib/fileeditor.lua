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
        file_editor.buffer = _G.filesystem.read(file_editor.active_dir, false)
    end)
    if not success then
        _G.shell.text(err, true)
        _G.package.keyboard.status = 0
    end
    file_editor.read()
end

function file_editor.read()
    local f = io.open(file_editor.active_dir)
    if f then
        local chars = 0
        for fline in f:lines() do
            table.insert(file_editor.buffer, fline)
            chars = chars + len(fline)
            if #buffer <= 25 then
                _G.invoke(_G.bootgpu, "set", 0, 0, #buffer)
            end
        end
    end
    f:close()
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
end

return file_editor