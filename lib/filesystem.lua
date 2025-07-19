local fs = {}
fs.mounts = {}

-- current working directory (for relative paths)
fs.directory = "."

-- default real filesystem proxy
local realfs = component.proxy(_G.bootAddress)

-- helper: normalize a path to absolute
local function normalize(path)
    if path:sub(1,1) == "/" then
        return path
    elseif fs.directory == "." then
        return path
    else
        return fs.directory:match("/$") and (fs.directory .. path) or (fs.directory .. "/" .. path)
    end
end

-- helper: resolve which filesystem to use and the subpath
local function resolve(path)
    local abs = normalize(path)
    -- try longest mount points first
    local bestMount, bestProxy
    for mountPoint, proxy in pairs(fs.mounts) do
        if abs:sub(1, #mountPoint) == mountPoint then
            if not bestMount or #mountPoint > #bestMount then
                bestMount = mountPoint
                bestProxy = proxy
            end
        end
    end
    if bestProxy then
        local subpath = abs:sub(#bestMount + 1)
        if subpath == "" then subpath = "/" end
        return bestProxy, subpath
    end
    return realfs, abs
end

function fs.makeDirectory(path)
    local proxy, p = resolve(path)
    return proxy.makeDirectory(p)
end

function fs.mount(mountPoint, address)
    local ok, proxy = pcall(component.proxy, address)
    if not ok or not proxy then
        _G.shell.text("Failed to mount new storage device", true)
        return false, proxy
    end
    -- ensure mount root exists
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
    return ok, err
end

function fs.list(path)
    local proxy, p = resolve(path)
    local ok, result = pcall(proxy.list, proxy, p)
    if not ok or not result then
        _G.shell.text("ERROR LISTING => " .. tostring(p) .. ": " .. tostring(result), true)
        return nil, result
    end
    for _, name in ipairs(result) do
        _G.shell.text("=> " .. p .. "/" .. name, true)
    end
    return result
end

function fs.exists(path)
    local proxy, p = resolve(path)
    return proxy.exists(p)
end

function fs.isDirectory(path)
    local proxy, p = resolve(path)
    return proxy.isDirectory(p)
end

function fs.size(path)
    local proxy, p = resolve(path)
    return proxy.size(p)
end

function fs.open(path, mode)
    local proxy, p = resolve(path)
    return proxy.open(p, mode)
end

function fs.print_file(path)
    local handle, reason = fs.open(path, "r")
    if not handle then return end
    while true do
        local chunk = realfs.read(handle, math.huge)
        if not chunk then break end
        _G.shell.text(chunk, true)
    end
    realfs.close(handle)
end

function fs.read(path, print)
    if print then
        return fs.print_file(path)
    end
    local handle, reason = fs.open(path, "r")
    if not handle then
        _G.shell.text("Failed to open file: " .. tostring(reason), true)
        return nil, reason
    end
    local contents = ""
    while true do
        local chunk = realfs.read(handle, math.huge)
        if not chunk then break end
        contents = contents .. chunk
    end
    realfs.close(handle)
    return contents
end

return fs
