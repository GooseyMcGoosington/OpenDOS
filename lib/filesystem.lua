local fs = {}
fs.mounts = {}

fs.directory = "."
local realfs = component.proxy(_G.bootAddress)

function fs.makeDirectory(path)
    realfs.makeDirectory(path)
end

function parseMountPath(path)
    path = path:gsub("^%./", "")
    local drive, subpath = path:match("^mnt/([%w%-]+)/(.*)$")
    if drive then
        return true, drive, "./" .. subpath
    elseif path:match("^mnt/[%w%-]+$") then
        drive = path:match("^mnt/([%w%-]+)$")
        return true, drive, "."
    else
        return false, "<unknown>", "<unknown>"
    end
end

function fs.mount(mountPoint, address)
    realfs.makeDirectory(mountPoint)
    fs.mounts[mountPoint] = component.proxy(address)
    return true
end

function fs.unmount(mountPoint)
    local proxy = fs.mounts[mountPoint]
    if not proxy then
        return false, ("No filesystem mounted at %s"):format(mountPoint)
    end
    fs.mounts[mountPoint] = nil
    local ok, err = pcall(realfs.remove, mountPoint)
    return true
end

fs.makeDirectory("/mnt")

function fs.list(path)
    local entries = {}

    local currentFS = realfs
    local isMounted, drive, subpath = parseMountPath(path)
    for mountPoint, proxy in pairs(fs.mounts) do
        local address = proxy.address or "<unknown>"
        _G.shell.text("Mount Point: " .. mountPoint .. " -> Address: " .. address, true)
    end
    if isMounted then
        currentFS = fs.mounts["./mnt/"..drive:sub(1, 8)]
        if currentFS then
            path = subpath
            _G.shell.text("Found mounted filesystem; " .. drive .. " " .. path, true)
        end
    end

    if type(path) ~= "string" then
        _G.shell.text("INVALID PATH" .. type(path), true)
        computer.beep(500, 0.1)
        return nil, "invalid path"
    end

    local ok, result = pcall(currentFS.list, path)
    if not ok or not result then
        _G.shell.text("ERROR LISTING => " .. path .. " " .. tostring(result), true)
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
    local currentFS = realfs
    local isMounted, drive, subpath = parseMountPath(path)

    if isMounted then
        local mountPath = "./mnt/"..drive:sub(1, 8)
        if fs.mounts[mountPath] then
            currentFS = fs.mounts[mountPath]
            path = subpath
        end
    end

    return currentFS.exists(path)
end

function fs.isDirectory(path)
    return realfs.isDirectory(path)
end

function fs.size(path)
    return realfs.size(path)
end

function fs.print_file(filePath)
    local currentFS = realfs
    local isMounted, drive, subpath = parseMountPath(filePath)

    if isMounted then
        local mountPath = "./mnt/"..drive:sub(1, 8)
        if fs.mounts[mountPath] then
            currentFS = fs.mounts[mountPath]
            filePath = subpath
        end
    end

    local handle, reason = currentFS.open(filePath)
    if not handle then
        return
    end

    local buffer = ""
    repeat
        local chunk = currentFS.read(handle, math.huge)
        if chunk then
            buffer = buffer .. chunk
        end
    until not chunk
    currentFS.close(handle)

    for line in buffer:gmatch("[^\r\n]+") do
        _G.shell.text(line, true)
    end
    if _G.package.keyboard ~= nil then
        _G.shell.currentLine = _G.shell.currentLine + 1
        _G.package.keyboard.getLineAsString()
    end
end

function fs.read(path, print)
    local currentFS = realfs
    local isMounted, drive, subpath = parseMountPath(path)

    if isMounted then
        local mountPath = "./mnt/"..drive:sub(1, 8)
        if fs.mounts[mountPath] then
            currentFS = fs.mounts[mountPath]
            path = subpath:gsub("^%.", "")
        end
    end

    if not print then
        local handle, reason = currentFS.open(path)
        if not handle then
            _G.shell.text("Failed to open file: " .. tostring(reason), true)
            return nil, reason
        else
            local contents = ""
            while true do
                local chunk = currentFS.read(handle, math.huge)
                if not chunk then break end
                contents = contents .. chunk
            end
            currentFS.close(handle)
            return contents
        end
    else
        fs.print_file(path)
    end
end

return fs
