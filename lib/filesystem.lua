local fs = {}
fs.mounts = {}

fs.directory = "." -- working directory
local realfs = component.proxy(_G.bootAddress)

-- Path normalization and resolution
local function normalize(path)
    if path:sub(1, 2) == "./" then
        path = fs.directory .. path:sub(2)
    elseif path:sub(1, 1) ~= "/" then
        path = fs.directory .. "/" .. path
    end
    path = path:gsub("/+", "/")       -- collapse multiple slashes
    path = path:gsub("/%./", "/")     -- remove /./
    path = path:gsub("/$", "")        -- remove trailing slash
    return path
end

local function resolve(path)
    path = normalize(path)
    for mountPoint, proxy in pairs(fs.mounts) do
        if path:sub(1, #mountPoint) == mountPoint then
            local relPath = path:sub(#mountPoint + 1)
            if relPath:sub(1, 1) == "/" then
                relPath = relPath:sub(2)
            end
            return proxy, relPath
        end
    end
    return realfs, path
end

-- Mounting
function fs.mount(mountPoint, address)
    local ok, proxy = pcall(component.proxy, address)
    if not ok or not proxy then
        _G.shell.text("Failed to mount new storage device", true)
        return false, proxy
    end
    realfs.makeDirectory(mountPoint)
    fs.mounts[mountPoint] = proxy
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

-- Auto-create /mnt on boot
fs.makeDirectory = function(path)
    local proxy, realPath = resolve(path)
    return proxy.makeDirectory(realPath)
end
fs.makeDirectory("/mnt")

-- File listing
function fs.list(path)
    local proxy, realPath = resolve(path)
    local entries = {}

    if type(realPath) ~= "string" then
        _G.shell.text("INVALID PATH: " .. type(realPath), true)
        computer.beep(500, 0.1)
        return nil, "invalid path"
    end

    local ok, result = pcall(proxy.list, realPath)
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

-- File exists
function fs.exists(path)
    local proxy, realPath = resolve(path)
    return proxy.exists(realPath)
end

-- Is directory?
function fs.isDirectory(path)
    local proxy, realPath = resolve(path)
    return proxy.isDirectory(realPath)
end

-- File size
function fs.size(path)
    local proxy, realPath = resolve(path)
    return proxy.size(realPath)
end

-- File read
function fs.read(path, printOutput)
    local proxy, realPath = resolve(path)

    if not printOutput then
        local handle, reason = proxy.open(realPath)
        if not handle then
            _G.shell.text("Failed to open file: " .. tostring(reason), true)
            return nil, reason
        else
            local contents = ""
            while true do
                local chunk = proxy.read(handle, math.huge)
                if not chunk then break end
                contents = contents .. chunk
            end
            proxy.close(handle)
            return contents
        end
    else
        local handle, reason = proxy.open(realPath)
        if not handle then return end
        local buffer = ""
        repeat
            local chunk = proxy.read(handle, math.huge)
            if chunk then
                buffer = buffer .. chunk
            end
        until not chunk
        proxy.close(handle)

        for line in buffer:gmatch("[^\r\n]+") do
            _G.shell.text(line, true)
        end
        if _G.package.keyboard ~= nil then
            _G.shell.currentLine = _G.shell.currentLine + 1
            _G.package.keyboard.getLineAsString()
        end
    end
end

-- Print file shortcut
function fs.print_file(path)
    fs.read(path, true)
end

-- Optional: Write file
function fs.write(path, data)
    local proxy, realPath = resolve(path)
    local handle, err = proxy.open(realPath, "w")
    if not handle then
        _G.shell.text("Failed to write file: " .. tostring(err), true)
        return nil, err
    end
    proxy.write(handle, data)
    proxy.close(handle)
    return true
end

return fs
