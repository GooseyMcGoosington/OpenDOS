local m, f, c = {}, 0, 0
while true do
  table.insert(m, "x")
  if #m % 1000 == 0 then _G.shell.text("Mem: " .. #m, true) end

  local r = 0
  for i = 1, 1e5 do r = r + i end

  c = c + 1
  local n = "/home/stressTestFile" .. c
  _G.shell.text("Write: " .. n, true)
  if c % 100 == 0 then _G.shell.text("FS: " .. n, true) end
end