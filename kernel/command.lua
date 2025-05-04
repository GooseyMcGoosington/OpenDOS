local command = {}
command.cmds = {
    "LIST",
    "CD",
    "READ",
    "RUN",
    "HELP",
    "CLEAR",
    "LCD"
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
        if cmd == "LIST" then
            _G.filesystem.list(_G.filesystem.directory)
        end
        if cmd == "CD" then
            if _G.filesystem.exists(parts[1]) then
                _G.filesystem.directory = parts[1]
            end
        end
        if cmd == "READ" then
            if _G.filesystem.exists(_G.filesystem.directory..parts[1]) then
                _G.filesystem.read(_G.filesystem.directory..parts[1], true)
            end
        end
        if cmd == "RUN" then
            _G.shell.text("UNAVAILABLE COMMAND", true)
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
    else
        _G.shell.text("INVALID COMMAND", true)
    end
end

return command
