local fs = {}
fs.mounts = {}

fs.directory = "."
local realfs = component.proxy(_G.bootAddress)

function fs.makeDirectory(path)
    realfs.makeDirectory(path)
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

local function resolve(path)
    for mountPoint, proxy in pairs(fs.mounts) do
        if path:sub(1, #mountPoint) == mountPoint then
            local subPath = path:sub(#mountPoint + 2)
            if subPath == "" then subPath = "." end
            return proxy, subPath
        end
    end
    return realfs, path
end

function fs.list(path)
  local entries = {}

  if type(path) ~= "string" then
    _G.shell.text("INVALID PATH" .. type(path), true)
    computer.beep(500, 0.1)
    return nil, "invalid path"
  end

  local proxy, subPath = resolve(path)
  local ok, result = pcall(proxy.list, subPath)
  if not ok or not result then
    _G.shell.text("ERROR LISTING => " .. path .. " / " .. tostring(result), true)
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
    local proxy, subPath = resolve(path)
    return proxy.exists(subPath)
end

function fs.isDirectory(path)
    local proxy, subPath = resolve(path)
    return proxy.isDirectory(subPath)
end

function fs.size(path)
    local proxy, subPath = resolve(path)
    return proxy.size(subPath)
end

function fs.print_file(filePath)
    local proxy, subPath = resolve(filePath)
    local handle, reason = proxy.open(subPath)
    if not handle then
        return
    end
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

function fs.read(path, print)
    if not print then
        local proxy, subPath = resolve(path)
        local handle, reason = proxy.open(subPath)
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
        fs.print_file(path)
    end
end

return fs
