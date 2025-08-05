local invoke=component.invoke
_G.gpu, _G.screen, _G.components, _G.screenbuffer = {}, {}, {}, {}
_G.bootscreen, _G.bootgpu, _G.filesystem = nil, nil, nil
_G.shell = {currentLine=1,fault=-1,dump="UNKNOWN ERROR REPORTED"}
_G.wh = {0,0}
_G.bootAddress = computer.getBootAddress()
_G.invoke = component.invoke
_G.package = {keyboard=nil, command=nil, utility=nil, fileeditor=nil}
local faultCodes = {
  [0]="FATAL: Vital Fault", [1]="FATAL: System Fault", [2]="FATAL: Out of Memory",
  [3]="FATAL: Hardware Fault", [4]="KERNEL: Software Load Failure",
  [5]="KERNEL: Software Exception", [6]="FATAL: Disk Failure"
}
local shutdown = computer.shutdown
computer.shutdown = function(reboot)
  if os.sleep then
    computer.pushSignal("shutdown")
    os.sleep(0.1)
  end
  shutdown(reboot)
end
function findComp()
  for address,ctype in component.list() do
    local t={address=address,ctype=ctype}
    if ctype=="gpu" then table.insert(_G.gpu,t)
    elseif ctype=="screen" then table.insert(_G.screen,t)
    else table.insert(_G.components,t) end
  end
end
function compAdd(addr)
  for _,t in pairs(_G.components) do if t.address==addr then return end end
  for _,t in pairs(_G.screen) do if t.address==addr then return end end
  for _,t in pairs(_G.gpu) do if t.address==addr then return end end
  local ctype = component.type(addr)
  local t = {address=addr,ctype=ctype}
  if ctype=="gpu" then table.insert(_G.gpu,t)
  elseif ctype=="screen" then table.insert(_G.screen,t)
  else
    _G.shell.text(ctype,true)
    if ctype=="filesystem" then
      local short = addr:sub(1,8)
      local mp = "./mnt/"..short.."/"
      local ok,err = _G.filesystem.mount(mp,addr)
      if not ok then _G.shell.text(err,true)
      else _G.shell.text("Mounted new drive at "..mp,true) end
      _G.shell.currentLine = _G.shell.currentLine + 1
    end
    table.insert(_G.components,t)
  end
end
function compRemove(addr)
  for i,t in pairs(_G.components) do
    if t.address==addr then
      if t.ctype=="filesystem" then
        local short = addr:sub(1,8)
        local mp = "./mnt/"..short.."/"
        local ok,err = _G.filesystem.unmount(mp)
        if not ok then _G.shell.text(err,true)
        else _G.shell.text("Unmounted drive at "..mp,true) end
        _G.shell.currentLine = _G.shell.currentLine + 1
        if _G.bootAddress == addr then _G.shell.fault=6 return end
      end
      table.remove(_G.components,i)
      return
    end
  end
  for i,t in pairs(_G.gpu) do if t.address==addr then table.remove(_G.gpu,i) return end end
  for i,t in pairs(_G.screen) do if t.address==addr then table.remove(_G.screen,i) return end end
end
function dofile(file)
  _G.shell.text("=> "..file,true)
  local prog,reason = loadfile(file)
  if prog then
    local res = table.pack(pcall(prog))
    if res[1] then return table.unpack(res,2,res.n)
    else _G.shell.fault=4 end
  else _G.shell.fault=4 end
end
function _G.shell.setScreenBuffer()
  local w,h=_G.wh[1],_G.wh[2]
  _G.screenbuffer = {}
  for i=1,w*h do _G.screenbuffer[i]=" " end
end
function _G.shell.wipeScreenBuffer()
  local w,h=_G.wh[1],_G.wh[2]
  local valid={}
  for x=1,w do for y=1,h do
    local i=(y-1)*w+x
    _G.screenbuffer[i]=" "
    valid[i]=true
  end end
  for k in pairs(_G.screenbuffer) do if not valid[k] then _G.screenbuffer[k]=nil end end
end
function _G.shell.setColour(f,b)
  invoke(_G.bootgpu,"setForeground",f)
  invoke(_G.bootgpu,"setBackground",b)
end
function _G.shell.clear(x0,y0,x1,y1,str)
  invoke(_G.bootgpu,"fill",x0,y0,x1,y1,str)
  _G.shell.currentLine=1
  _G.shell.wipeScreenBuffer()
end
function _G.shell.text(str,setColour)
  local x,y = 1,_G.shell.currentLine+1
  if setColour then _G.shell.setColour(0xFFFFFF,0x0000FF) end
  invoke(_G.bootgpu,"set",x,y,str)
  for i=1,#str do _G.shell.writeChar(x+i-1,y,str:sub(i,i)) end
  _G.shell.currentLine = y
end
function _G.shell.writeChar(x,y,c)
  local w,h = _G.wh[1],_G.wh[2]
  x = math.max(1, math.min(x,w))
  y = math.max(1, math.min(y,h))
  _G.screenbuffer[(y-1)*w+x]=c
end
function _G.shell.readChar(x,y)
  local w,h = _G.wh[1],_G.wh[2]
  x = math.max(1, math.min(x,w))
  y = math.max(1, math.min(y,h))
  return _G.screenbuffer[(y-1)*w+x] or " "
end
function _G.shell.sleep(sec)
  local dl = computer.uptime()+sec
  repeat computer.pullSignal(dl-computer.uptime()) until computer.uptime()>=dl
end
function _G.shell.panic()
  _G.shell.setColour(0xFFFFFF,0xFF0000)
  _G.shell.clear(1,1,_G.wh[1],_G.wh[2]," ")
  _G.shell.text(faultCodes[_G.shell.fault],false)
  _G.shell.text("Panic triggered.",false)
  _G.shell.text("A crash dump is unavailable.",false)
  _G.shell.text(_G.shell.dump,false)
  _G.shell.text("This system will shutdown in 5 seconds.",false)
  _G.shell.sleep(5)
  computer.shutdown(false)
end
function _G.shell.run(path,...)
  local chunk,err=_G.filesystem.read(path,false)
  if not chunk then
    _G.shell.text("FATAL: CANNOT LOAD : "..tostring(err),true)
    _G.shell.currentLine = _G.shell.currentLine + 1
    return false
  end
  local program = assert(load(chunk))()
  return true, result
end
function clr()
  _G.shell.setColour(0x000000,0x0000FF)
end
function vital()
  _G.bootgpu = component.list("gpu")()
  _G.bootscreen = component.list("screen")()
  invoke(_G.bootgpu,"bind",_G.bootscreen)
  local w,h = invoke(_G.bootgpu,"getResolution")
  _G.wh = {w,h}
  clr()
  _G.shell.clear(1,1,w,h," ")
  _G.shell.setScreenBuffer()
end
function panicLowMem()
  local used = (computer.totalMemory()-computer.freeMemory())/computer.totalMemory()
  if used >= 0.96 then
    _G.shell.fault = 2
    _G.shell.dump = "MEMORY USAGE TOO HIGH"
    _G.shell.panic()
  end
end
local success, _ = pcall(function()
  findComp()
  vital()
end)
if success and _G.shell.fault == -1 then
  computer.beep(1500,0.1)
  _G.shell.text("Basic System Checks OK.",true)
  _G.shell.text("Please wait.",true)
  local success,msg = pcall(function()
    _G.shell.text("Loading Lib",true)
    _G.filesystem = dofile("/lib/filesystem.lua")
    local short = _G.bootAddress:sub(1,8)
    local mp = "./mnt/"..short
    _G.filesystem.mount(mp,_G.bootAddress)
    _G.package.utility = dofile("/lib/utility.lua")
    _G.package.fileeditor = dofile("/lib/fileeditor.lua")
    _G.shell.text("Loading Kernel",true)
    _G.package.keyboard = dofile("/kernel/keyboard.lua")
    _G.package.command = dofile("/kernel/command.lua")
  end)
  if not success then
    _G.shell.fault = 4
    _G.shell.dump = msg
  else
    _G.shell.text("Finished Loading Software",true)
    _G.shell.sleep(1)
    _G.shell.clear(1,1,_G.wh[1],_G.wh[2]," ")
    _G.filesystem.directory = "./home/"
    _G.filesystem.read(_G.filesystem.directory.."/hello_world.txt",true)
    _G.package.utility.report()
    _G.shell.text("OK.",true)
    _G.shell.currentLine = _G.shell.currentLine + 1
  end
  while true do
    local e,addr,ascii,code,d = computer.pullSignal(0.05)
    panicLowMem()
    if _G.shell.fault>-1 then _G.shell.panic() return end
    local success,msg = pcall(function()
      local char = ascii and string.char(ascii) or ""
      if _G.package.keyboard.status==0 then
        _G.package.keyboard.update(e,code,char,ascii)
      elseif _G.package.keyboard.status>0 then
        _G.package.fileeditor.update(e,code,char,ascii,d)
      end
    end)
    local success,msg = pcall(function()
      if e=="component_added" then compAdd(addr)
      elseif e=="component_removed" then compRemove(addr) end
    end)
    if not success then
      _G.shell.fault=5
      _G.shell.dump=msg
      _G.shell.panic()
    end
    if _G.shell.currentLine >= _G.wh[2] then
      _G.shell.setColour(0xFFFFFF,0x0000FF)
      _G.shell.clear(1,1,_G.wh[1],_G.wh[2]," ")
    end
    panicLowMem()
  end
else
  _G.shell.sleep(0.1)
  computer.beep(500,0.05)
  computer.beep(500,0.05)
  computer.beep(500,0.05)
  _G.shell.panic()
end
