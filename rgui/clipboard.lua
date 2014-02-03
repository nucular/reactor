--[[ Lua library to interact with the clipboard ]]--
--by nucular

-- On Linux with X we use xclip, on Cygwin we use /dev/clipboard and on Mac OS
-- we use pbpaste and pbcopy. On Winderp it's tricky, we need to use clip.exe
-- for writing and an external AutoHotKey script for reading.

clipboard = {}

function clipboard.win_write(text)
    local f = io.popen("clip.exe", "w")
    f:write(text)
    f:close()
end

function clipboard.lin_write(text)
    local f = io.popen("xclip", "w")
    f:write(text)
    f:close()
end

function clipboard.cyg_write(text)
    local f = io.popen("/dev/clipboard", "w")
    f:write(text)
    f:close()
end