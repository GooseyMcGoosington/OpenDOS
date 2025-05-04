local addr = computer.getBootAddress()
local fs   = component.proxy(addr)

local function loadfile(file)
  local handle, reason = fs.open(file)
  if not handle then
    error("Failed to open " .. file .. ": " .. tostring(reason))
  end

  local buffer = ""
  repeat
    -- read as much as possible each iteration
    local data = fs.read(handle, math.huge)
    buffer = buffer .. (data or "")
  until not data

  fs.close(handle)
  -- load in the global environment, binary/text mode
  return load(buffer, "=" .. file, "bt", _G)
end

local ok, err = pcall(function()
  loadfile("/shell/shell.lua")(loadfile)
end)
if not ok then
  error("Boot error: " .. err)
end
