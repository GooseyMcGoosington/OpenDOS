local command = {}
command.cmds = {
    "LIST",
    "CD",
    "READ",
    "RUN",
    "HELP"
}

-- Helper: check if a value is in a list
local function isInList(val, list)
    for _, v in ipairs(list) do
        if v == val then return true end
    end
    return false
end

-- Parse a command string into {command = ..., args = {...}}
command.parse = function(str)
    str = str:match("^%s*(.-)%s*$") -- trim
    local parts = {}
    for word in str:gmatch("%S+") do
        table.insert(parts, word)
    end

    local cmd = parts[1] and string.upper(parts[1])
    table.remove(parts, 1)

    if isInList(cmd, command.cmds) then
        if cmd == "LIST" then
            _G.filesystem.list(parts[1])
        end
        if cmd == "CD" then
            if _G.filesystem.exists(parts[1]) then
                _G.filesystem.directory = parts[1]
            end
        end
        if cmd == "READ" then
            if _G.filesystem.exists(parts[1]) then
                _G.filesystem.read(parts[1], true)
            end
        end
        if cmd == "RUN" then
            _G.shell.text("UNAVAILABLE COMMAND", true)
        end
        if cmd == "HELP" then
            for command, _ in pairs(command.cmds) do
                _G.shell.text("=> ", command, true)
            end
        end
    else
        _G.shell.text("INVALID COMMAND", true)
    end
end

return command
