local command = {}
command.cmds = {
    "LIST",
    "CD",
    "READ",
    "RUN",
    "HELP",
    "CLEAR",
    "LCD",
    "REPORT",
    "MKDIR",
    "RMDIR"
}
local function isInList(val, list)
    for _, v in ipairs(list) do
        if v == val then return true end
    end
    return false
end
command.parse = function(str)
    str = str:match("^%s*(.-)%s*$")
    local parts = {}
    for word in str:gmatch("%S+") do
        table.insert(parts, word)
    end

    local cmd = parts[1] and string.upper(parts[1])
    table.remove(parts, 1)

    if isInList(cmd, command.cmds) then
        local success, msg = pcall(function()
            if cmd == "LIST" then
                _G.filesystem.list(_G.filesystem.directory)
            end
            if cmd == "CD" then
                local dir = parts[1]
                if (string.sub(dir, 1, 2) == "..") then
                    _G.filesystem.directory = _G.filesystem.directory:gsub("/$", ""):match("^(.*)/[^/]*$"):gsub("/*$", "/")
                    if _G.filesystem.directory == "." then
                        _G.filesystem.directory = "./"
                    end
                else
                    if string.sub(dir, 1, 2) == "./" then
                        if _G.filesystem.exists(dir) then
                            _G.filesystem.directory = dir:gsub("/*$", "/")
                        end
                    else
                        dir = _G.filesystem.directory:gsub("/*$", "/") .. dir
                        if _G.filesystem.exists(dir) then
                            _G.filesystem.directory = dir:gsub("/*$", "/")
                        end
                    end
                end
                if string.sub(_G.filesystem.directory , -1) ~= "/" then
                    _G.filesystem.directory = _G.filesystem.directory .. "/"
                end
            end
            if cmd == "READ" then
                if _G.filesystem.exists(_G.filesystem.directory..parts[1]) then
                    _G.filesystem.read(_G.filesystem.directory..parts[1], true)
                end
            end
            if cmd == "RUN" then
                if _G.filesystem.exists(_G.filesystem.directory..parts[1]) then
                    _G.shell.run(_G.filesystem.directory..parts[1])
                end
            end
            if cmd == "HELP" then
                for _, command in pairs(command.cmds) do
                    _G.shell.text("=> ".. command, true)
                end
            end
            if cmd == "CLEAR" then
                _G.shell.setColour(0xFFFFFF, 0x0000FF)
                _G.shell.clear(1, 1, _G.wh[1], _G.wh[2], " ")
            end
            if cmd == "LCD" then
                _G.shell.text("=> " .. _G.filesystem.directory, true)
            end
            if cmd == "REPORT" then
                _G.package.utility.report()
            end
            if cmd == "MKDIR" then
                local dir = parts[1]
                local dirname = parts[2]
                -- If it starts with ./, it's absolute. Otherwise it is relative.
                if (string.sub(dir, 1, 2) == "./") then
                    if _G.filesystem.exists(dir) then
                        dir = dir:gsub("/*$", "/")
                    end
                else
                    dir = _G.filesystem.directory:gsub("/*$", "/") .. dir
                    _G.filesystem.exists(dir)
                end
                _G.shell.text("The MKDIR Directory is: " .. dir, true)
                _G.filesystem.mkdir(dir, dirname)
            end
        end)
        if not success then
            _G.shell.text("FATAL: PARSER FAULT", true)
            _G.shell.text(msg, true)
        end
    else
        _G.shell.text("INVALID COMMAND", true)
    end
end

return command
