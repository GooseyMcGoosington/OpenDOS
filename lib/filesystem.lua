local fs = {}
fs.mounts = {}

fs.directory = "."
local realfs = component.proxy(_G.bootAddress)

-- Utility to split path into components by '/'
local function splitPath(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  return parts
end

-- Helper to check if path is under a mounted path, return mount proxy and relative path if so
local function getMountProxyAndRelPath(path)
    local parts = splitPath(path)
    if parts[1] == "." and parts[2] == "mnt" and parts[3] and fs.mounts[parts[3]] then
        local mountProxy = fs.mounts["/mnt/"..parts[3]:sub(1,8)]
        local relPath = table.concat({select(4, table.unpack(parts))}, "/")
        if relPath == "" then relPath = "/" end
        return mountProxy, relPath
    end
    return nil, nil
end

function fs.makeDirectory(path)
    local mountProxy, relPath = getMountProxyAndRelPath(path)
    if mountProxy then
        return mountProxy.makeDirectory(relPath)
    else
        return realfs.makeDirectory(path)
    end
end

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

fs.makeDirectory("/mnt")

function fs.list(path)
    local mountProxy, relPath = getMountProxyAndRelPath(path)
    local entries = {}

    if mountProxy then
        local ok, result = pcall(mountProxy.list, relPath)
        if not ok or not result then
            _G.shell.text("ERROR LISTING => " .. path .. "/ " .. tostring(result), true)
            computer.beep(500, 0.1)
            return nil, result
        end
        for _, name in ipairs(result) do
            table.insert(entries, name)
            _G.shell.text("=> " .. path .. "/" .. name, true)
        end
    else
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
    end

    if _G.package.keyboard ~= nil then
        _G.shell.currentLine = _G.shell.currentLine + 1
        _G.package.keyboard.getLineAsString()
    end
    return entries
end

function fs.exists(path)
    local mountProxy, relPath = getMountProxyAndRelPath(path)
    if mountProxy then
        return mountProxy.exists(relPath)
    else
        return realfs.exists(path)
    end
end

function fs.isDirectory(path)
    local mountProxy, relPath = getMountProxyAndRelPath(path)
    if mountProxy then
        return mountProxy.isDirectory(relPath)
    else
        return realfs.isDirectory(path)
    end
end

function fs.size(path)
    local mountProxy, relPath = getMountProxyAndRelPath(path)
    if mountProxy then
        return mountProxy.size(relPath)
    else
        return realfs.size(path)
    end
end

function fs.print_file(filePath)
    local mountProxy, relPath = getMountProxyAndRelPath(filePath)
    local handle, reason
    if mountProxy then
        handle, reason = mountProxy.open(relPath)
    else
        handle, reason = realfs.open(filePath)
    end
    if not handle then
        --_G.shell.text("Error opening file: " .. tostring(reason), true)
        return
    end

    local buffer = ""
    repeat
        local chunk
        if mountProxy then
            chunk = mountProxy.read(handle, math.huge)
        else
            chunk = realfs.read(handle, math.huge)
        end
        if chunk then buffer = buffer .. chunk end
    until not chunk

    if mountProxy then
        mountProxy.close(handle)
    else
        realfs.close(handle)
    end

    for line in buffer:gmatch("[^\r\n]+") do
        _G.shell.text(line, true)
    end
    if _G.package.keyboard ~= nil then
        _G.shell.currentLine = _G.shell.currentLine + 1
        _G.package.keyboard.getLineAsString()
    end
end

function fs.read(path, print)
    local mountProxy, relPath = getMountProxyAndRelPath(path)

    if mountProxy then
        if not print then
            local handle, reason = mountProxy.open(relPath)
            if not handle then
                _G.shell.text("Failed to open file on mount: " .. tostring(reason), true)
                return nil, reason
            else
                local contents = ""
                while true do
                    local chunk = mountProxy.read(handle, math.huge)
                    if not chunk then break end
                    contents = contents .. chunk
                end
                mountProxy.close(handle)
                return contents
            end
        else
            fs.print_file(path)
        end
    else
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
end

return fs
