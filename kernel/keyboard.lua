local keyboard = {}

-- This should take in the screen buffer
keyboard.x = 1
keyboard.y = 1
local K = 0

keyboard.update = function(e, code)
    if K % 4 == 0 then
        local char = _G.shell.readChar(keyboard.x, keyboard.y)
        if char then
            _G.shell.setColour(0x000000, 0xFFFFFF)
            _G.shell.text(char, false) 
            _G.clr()
        end
        K = 0
    end
    K = K + 1
end

return keyboard