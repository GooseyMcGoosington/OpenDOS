local memoryStress = {}
local function stressMemory()
    while true do
        table.insert(memoryStress, "data")  -- Keep inserting to consume memory
        if #memoryStress % 1000 == 0 then
            _G.shell.text("Memory stress test: " .. #memoryStress .. " entries", true)
        end
    end
end

local function stressCpu()
    while true do
        local result = 0
        for i = 1, 100000 do
            result = result + i  -- Sum numbers as a CPU-heavy task
        end
    end
end

local function stressFilesystem()
    local fileData = "Stress testing the file system with this data."
    local fileCount = 0
    while true do
        fileCount = fileCount + 1
        local fileName = "/home/stressTestFile" .. fileCount
        _G.shell.text("Simulating file write: " .. fileName, true)
        if fileCount % 100 == 0 then
            _G.shell.text("Filesystem stress test: Created and wrote to " .. fileName, true)
        end
    end
end
stressMemory()
stressCpu()
stressFilesystem()
