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

local function splitPath(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  return parts
end

function fs.print_file(filePath)
    local parts = splitPath(filePath)
    -- Check if path is under ./mnt/<mountPoint>/...
    if parts[1] == "." and parts[2] == "mnt" and parts[3] and fs.mounts[parts[3]] then
        local mountProxy = fs.mounts[parts[3]]
        -- Build relative path inside mounted fs
        local relPath = table.concat({select(4, table.unpack(parts))}, "/")
        if relPath == "" then relPath = "/" end
        local handle, reason = mountProxy.open(relPath)
        if not handle then
            --_G.shell.text("Error opening file on mount: " .. tostring(reason), true)
            return
        end
        local buffer = ""
        repeat
            local chunk = mountProxy.read(handle, math.huge)
            if chunk then buffer = buffer .. chunk end
        until not chunk
        mountProxy.close(handle)

        for line in buffer:gmatch("[^\r\n]+") do
            _G.shell.text(line, true)
        end
        if _G.package.keyboard ~= nil then
            _G.shell.currentLine = _G.shell.currentLine + 1
            _G.package.keyboard.getLineAsString()
        end
    else
        -- Not mounted, use realfs
        local handle, reason = realfs.open(filePath)
        if not handle then
            --_G.shell.text("Error opening file: " .. tostring(reason), true)
            return
        end
        local buffer = ""
        repeat
            local chunk = realfs.read(handle, math.huge)
            if chunk then buffer = buffer .. chunk end
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
end

function fs.read(path, print)
    local parts = splitPath(path)
    if parts[1] == "." and parts[2] == "mnt" and parts[3] and fs.mounts[parts[3]] then
        local mountProxy = fs.mounts[parts[3]]
        local relPath = table.concat({select(4, table.unpack(parts))}, "/")
        if relPath == "" then relPath = "/" end

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
            -- Print via fs.print_file for this path
            fs.print_file(path)
        end
    else
        -- Use realfs as fallback
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
