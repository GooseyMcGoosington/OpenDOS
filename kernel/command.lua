local command = {}
command.cmds = {
  "DIR", "CD", "TYPE", "RUN", "HELP", "CLS",
  "PWD", "STAT", "MD", "RD", "EDIT"
}

local function isInList(val, list)
  for _, v in ipairs(list) do
    if v == val then return true end
  end
end

local function absPath(p)
  return (p or ""):sub(1, 2) == "./" and p or (_G.filesystem.directory:gsub("/*$", "/") .. (p or ""))
end

local function splitPath(p1, p2)
  return absPath(p1 or ""), p2 or ""
end

command.parse = function(str)
  str = str:match("^%s*(.-)%s*$")
  local parts = {}
  for w in str:gmatch("%S+") do table.insert(parts, w) end

  local cmd = parts[1] and string.upper(table.remove(parts, 1))
  if not isInList(cmd, command.cmds) then
    _G.shell.text("INVALID COMMAND", true)
    return
  end

  local ok, msg = pcall(function()
    local fs, sh, pkg = _G.filesystem, _G.shell, _G.package

    if cmd == "DIR" then
      fs.list(fs.directory)

    elseif cmd == "CD" then
      local d = parts[1]
      if d == ".." or (d and d:sub(1, 2) == "..") then
        fs.directory = fs.directory:gsub("/$", ""):match("^(.*)/[^/]*$"):gsub("/*$", "/")
        if fs.directory == "." then fs.directory = "./" end
      else
        local full = absPath(d)
        if fs.exists(full) then
          fs.directory = full:gsub("/*$", "/")
        end
      end

    elseif cmd == "TYPE" and parts[1] then
      local path = absPath(parts[1])
      if fs.exists(path) then fs.read(path, true) end

    elseif cmd == "RUN" and parts[1] then
      local path = absPath(parts[1])
      if fs.exists(path) then sh.run(path) end

    elseif cmd == "HELP" then
      for _, c in ipairs(command.cmds) do sh.text("> " .. c, true) end

    elseif cmd == "CLS" then
      sh.setColour(_G.colours.fg, _G.colours.bg)
      sh.clear(1, 1, _G.wh[1], _G.wh[2], " ")
      sh.currentLine = 1
      
    elseif cmd == "PWD" then
      sh.text("> " .. fs.directory, true)

    elseif cmd == "STAT" then
      pkg.utility.report()

    elseif cmd == "MD" then
      local base, sub = splitPath(parts[1], parts[2])
      if fs.exists(base) then fs.mkdir(base:gsub("/*$", "/"), sub) end

    elseif cmd == "RD" then
      local base, sub = splitPath(parts[1], parts[2])
      if fs.exists(base) then fs.rmdir(base:gsub("/*$", "/"), sub) end

    elseif cmd == "EDIT" then
        local base, sub = splitPath(parts[1], parts[2])
        base = base:gsub("/*$", "/")
        _G.shell.text(base, true)
        _G.shell.text(sub, true)
        if not fs.exists(base .. sub) then
            _G.filesystem.write(base, sub, "") -- create an empty file
        end

        pkg.keyboard.status = 1
        pkg.fileeditor.load(base, sub)
    end
    if fs.directory:sub(-1) ~= "/" then fs.directory = fs.directory .. "/" end
  end)

  if not ok then
    _G.shell.text("FATAL: PARSER FAULT", true)
    _G.shell.text(msg, true)
  end
end

return command
