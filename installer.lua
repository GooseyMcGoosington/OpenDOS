local component = require("component")
local internet = require("internet")
local fs = require("filesystem")

io.write("Enter the path you want to write into: ")
local basePath = "/mnt/"..io.read()
io.write("Do you want to continue? The path " .. basePath .. " will be wiped. Please verify that THIS PATH is correct before proceeding! [Y/N]")
if io.read():lower() == "y" then
    local function clearDirectory(path)
        for file in fs.list(path) do
            local fullPath = fs.concat(path, file)
            if fs.isDirectory(fullPath) then
                clearDirectory(fullPath)
                fs.remove(fullPath)
            else
                fs.remove(fullPath)
            end
        end
    end

    if fs.exists(basePath) then
        clearDirectory(basePath)
    else
        print("Path does not exist. Retry")
        return
    end
    local files = {
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/init.lua", path = basePath .. "/init.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/home/hello_world.txt", path = basePath .. "/home/hello_world.txt" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/home/test.lua", path = basePath .. "/home/test.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/kernel/keyboard.lua", path = basePath .. "/kernel/keyboard.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/kernel/keycodes.lua", path = basePath .. "/kernel/keycodes.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/kernel/command.lua", path = basePath .. "/kernel/command.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/lib/filesystem.lua", path = basePath .. "/lib/filesystem.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/shell/shell.lua", path = basePath .. "/shell/shell.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/lib/utility.lua", path = basePath .. "/lib/utility.lua" },
        { url = "https://raw.githubusercontent.com/GooseyMcGoosington/OpenDOS/main/lib/fileeditor.lua", path = basePath .. "/lib/fileeditor.lua" },
      }
      
      for _, file in ipairs(files) do
        -- Ensure directory exists
        fs.makeDirectory(file.path:match("(.*/)[^/]*$"))
        local handle = internet.request(file.url)
        local content = ""
        for chunk in handle do
          content = content .. chunk
        end
        local f = io.open(file.path, "w")
        f:write(content)
        f:close()
        print("Written to: " .. file.path)
      end      
end