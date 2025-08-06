local gpu = _G.bootgpu
local keycodes = _G.package.keycodes.keys

local file_editor = {}
file_editor.active_dir = nil
file_editor.cursorX, file_editor.cursorY = 1, 1
file_editor.lineX = 0;
file_editor.lineY = 1;
file_editor.maxWidth = 80
file_editor.buffer = { "" }

file_editor.path = ""
file_editor.name = ""

local originalChar = nil

local term = {}
term.doBlink = true
term.state = true -- false for lastChar, true for blink
term.char = " "
term.lx = 0
term.ly = 0
local ctrl=false

term.blink = function()
    local bufferY = file_editor.lineY-1
    if term.doBlink then
        term.state = not term.state
        if term.state then
            term.lx = file_editor.cursorX
            term.ly = file_editor.cursorY-bufferY
            term.char = _G.invoke(gpu, "get", term.lx, term.ly) or " "
            _G.invoke(gpu, "set", term.lx, term.ly, "_")
        else
            _G.invoke(gpu, "set", term.lx, term.ly, term.char or " ")
        end
    end
end

function file_editor.load(path, name)
    file_editor.cursorX = 1
    file_editor.cursorY = 1
    term.lx = 0
    term.ly = 0
    term.char = " "
    term.state = true
    ctrl = false
    file_editor.lineX = 0;
    file_editor.lineY = 1;
    local filePath = path .. name
    -- check if mounted
    local currentFS = _G.filesystem.realfs
    local isMounted, drive, subpath = _G.filesystem.parseMountPath(path)

    if isMounted then
        local mountPath = "./mnt/"..drive:sub(1, 8) .. "/"
        if _G.filesystem.mounts[mountPath] then
            currentFS = _G.filesystem.mounts[mountPath]
            path = subpath
        end
    end
    --
    file_editor.active_dir = filePath
    file_editor.path=path
    file_editor.name=name
    local oldCX = file_editor.cursorX
    local oldCY = file_editor.cursorY
    file_editor.buffer = { "" }
    local success, err = pcall(function()
        local str = _G.filesystem.read(file_editor.active_dir, false) or "" -- Reading may return nil if nothing exists in the file.
        for i = 1, #str do
            local c = str:sub(i, i)

            if c == "\n" then
                file_editor.cursorY = file_editor.cursorY + 1
                file_editor.cursorX = 1
                file_editor.buffer[file_editor.cursorY] = ""
            else
                file_editor.buffer[file_editor.cursorY] = file_editor.buffer[file_editor.cursorY] .. c
                file_editor.cursorX = file_editor.cursorX + 1
            end
        end
    end)
    if not success then
        _G.shell.text(err, true)
        _G.package.keyboard.status = 0
    end
    if #file_editor.buffer == 0 then
        file_editor.buffer[1] = ""
        file_editor.cursorX = 1
        file_editor.cursorY = 1
    else
        file_editor.cursorX = oldCX
        file_editor.cursorY = oldCY
    end
    _G.shell.clear(0, 0, _G.wh[1], _G.wh[2], " ")
    file_editor.read()
end

function file_editor.save(path, name)
    local str = ""
    local maxLine = math.max(#file_editor.buffer, file_editor.cursorY)
    for i = 1, maxLine do
        str = str .. (file_editor.buffer[i] or "")
        if i < maxLine then
            str = str .. "\n"
        end
    end
    _G.filesystem.write(path, name, str)
end

function file_editor.set_status(x, y, text)
    _G.invoke(gpu, "set", x, y, text)
end

function file_editor.insert_char(value)
    local bufferY = file_editor.lineY - 1
    local y = file_editor.cursorY
    local x = file_editor.cursorX
    file_editor.buffer[y] = file_editor.buffer[y] or ""
    local line = file_editor.buffer[y]
    if #line < x - 1 then
        line = line .. (" "):rep(x - 1 - #line)
    end
    local before = line:sub(1, x - 1)
    local after = line:sub(x)
    file_editor.buffer[y] = before .. value .. after
    file_editor.cursorX = file_editor.cursorX + 1
    _G.invoke(gpu, "set", 1 - file_editor.lineX, y-(file_editor.lineY-1), file_editor.buffer[y])
    term.state = false
    term.blink()
end

function file_editor.enter()
    local y = file_editor.cursorY
    local x = file_editor.cursorX
    file_editor.buffer[y] = file_editor.buffer[y] or ""
    local line = file_editor.buffer[y]
    local before = line:sub(1, x - 1)
    local after = line:sub(x)
    for i = #file_editor.buffer, y + 1, -1 do
        file_editor.buffer[i + 1] = file_editor.buffer[i]
    end
    file_editor.buffer[y] = before
    file_editor.buffer[y + 1] = after
    file_editor.cursorY = y + 1
    file_editor.cursorX = 1
    file_editor.read()
    term.state = false
    term.blink()
end

function file_editor.delete_char()
    local bufferY = file_editor.lineY - 1
    local y = file_editor.cursorY
    local x = file_editor.cursorX
    file_editor.buffer[y] = file_editor.buffer[y] or ""
    local line = file_editor.buffer[y]
    if x > 1 then
        local before = line:sub(1, x - 2)
        local after = line:sub(x)
        file_editor.buffer[y] = before .. after
        file_editor.cursorX = x - 1
    end
    file_editor.cursorX = math.max(1, file_editor.cursorX)
    _G.invoke(gpu, "set", 1 - file_editor.lineX, y - bufferY, string.rep(" ", _G.wh[1]))
    _G.invoke(gpu, "set", 1 - file_editor.lineX, y - bufferY, file_editor.buffer[y])

    term.state = false
    term.blink()
end


function file_editor.read()
    _G.shell.clear(0, 0, _G.wh[1], _G.wh[2], " ")
    local bufferY = file_editor.lineY-1
    for sY = bufferY, bufferY + 24 do
        local line = file_editor.buffer[sY] or ""
        local i = 1
        local x = 1-file_editor.lineX
        local ly = sY-bufferY

        if (ly > 0 and ly < _G.wh[2]) then
            _G.invoke(gpu, "set", 1, ly, line:sub(file_editor.lineX+1, file_editor.lineX+_G.wh[1]))
        end
    end
end

function file_editor.update(e, code, char, ascii, d)
    term.blink()
    if e == "scroll" then
        local direction = d
        local old = term.ly
        if (direction > 0) then
            file_editor.lineY = file_editor.lineY - 5
            term.ly = term.ly + 1
        elseif (direction < 0) then
            file_editor.lineY = file_editor.lineY + 5
            term.ly = term.ly - 1
        end
        if file_editor.lineY < 1 then
            file_editor.lineY = 1
            term.ly = old
        end
        file_editor.read()
    end
    if e == "key_down" then
        if code == keycodes.lcontrol then
            ctrl = true
        end
        if code == keycodes.s and ctrl then
            -- save
            file_editor.save(file_editor.path, file_editor.name)
            --_G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
            --file_editor.buffer = {} -- Free buffer
            --_G.package.keyboard.status = 0 -- Keyboard active
        end
        if code == keycodes.w and ctrl then
            -- close
            _G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
            file_editor.buffer = {} -- Free buffer
            _G.package.keyboard.status = 0 -- Keyboard active
        end
        if code == keycodes.enter then -- Enter
            file_editor.enter()
        end
        if ascii >= 32 and ascii <= 126 then
            file_editor.insert_char(char)
        end
        if code == keycodes.back then
            file_editor.delete_char()
        elseif code == keycodes.left then
            file_editor.cursorX = file_editor.cursorX - 1
        elseif code == keycodes.right then
            file_editor.cursorX = file_editor.cursorX + 1
        elseif code == keycodes.up then
            file_editor.cursorY = file_editor.cursorY - 1
        elseif code == keycodes.down then
            file_editor.cursorY = file_editor.cursorY + 1
        end
        if (file_editor.cursorX < 0) then
            file_editor.cursorX = 0
        end
        if (file_editor.cursorY < 0) then
            file_editor.cursorY = 0
        end
    end
    if e == "key_up" then
        if code == keycodes.lcontrol then
            ctrl=false
        end
    end
    if file_editor.cursorX > file_editor.lineX + _G.wh[1] then
        file_editor.lineX = file_editor.cursorX - _G.wh[1]
        file_editor.read()
    end
    if file_editor.cursorX < file_editor.lineX then
        file_editor.lineX = file_editor.cursorX - 1
        file_editor.read()
    end
    if file_editor.lineX < 0 then
        file_editor.lineX = 0
    end
    _G.invoke(gpu, "set", 1, _G.wh[2], string.rep(" ", _G.wh[1]))
    file_editor.set_status(0, _G.wh[2], "MEM: " .. tostring(computer.freeMemory()) .. " " .. "X/Y: " .. tostring(file_editor.cursorX) .. "," .. tostring(file_editor.cursorY) .. " [CTRL+S] SAVE" .. " [CTRL+W] CLOSE")
end

return file_editor