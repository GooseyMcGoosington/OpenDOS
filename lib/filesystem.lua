local fs = {}
fs.directory = "."
local realfs = component.proxy(_G.bootAddress)

function fs.list(path)
    local entries = {}

    if type(path) ~= "string" then
        _G.shell.text("INVALID PATH" .. type(path), true)
        computer.beep(500, 0.1)
        return nil, "invalid path"
    end
    local ok, result = pcall(realfs.list, path)
    if not ok or not result then
        _G.shell.text("ERROR LISTING => " .. path .. "/ " .. tostring(result), true)
        computer.beep(500, 0.1)
        return nil, result
    end
    for _, name in ipairs(result) do
        table.insert(entries, name)
        _G.shell.text("=> " .. path .. "/" .. name, true)
    end
    if _G.package.keyboard ~= nil then
        _G.shell.currentLine = _G.shell.currentLine + 1
        _G.package.keyboard.getLineAsString()
    end
    return entries
end

function fs.exists(path)
    return realfs.exists(path)
end

function fs.isDirectory(path)
    return realfs.isDirectory(path)
end

function fs.size(path)
    return realfs.size(path)
end

function fs.print_file(filePath)
    local handle, reason = realfs.open(filePath)
    if not handle then
        --_G.shell.text("Error opening file: " .. tostring(reason), true)
        return
    end
    local buffer = ""
    repeat
        local chunk = realfs.read(handle, math.huge)
        if chunk then
            buffer = buffer .. chunk
        end
    until not chunk
    realfs.close(handle)

    for line in buffer:gmatch("[^\r\n]+") do
        _G.shell.text(line, true)
    end
    if _G.package.keyboard ~= nil then
        _G.shell.currentLine = _G.shell.currentLine + 1
        _G.package.keyboard.getLineAsString()
    end
end

function fs.read(path, print)
    if not print then
        local handle, reason = realfs.open(path)
        if not handle then
            _G.shell.text("Failed to open file: " .. tostring(reason), true)
            return nil, reason
        else
            local contents = ""
            while true do
                local chunk = realfs.read(handle, math.huge)
                if not chunk then break end
                contents = contents .. chunk
            end
            realfs.close(handle)
            return contents
        end
    else
        fs.print_file(path)
    end
end


return fs
