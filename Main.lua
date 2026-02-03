-- Минимальный вайт-лист
local url = "https://github.com/vixsur737/Crasher/blob/main/Whitelist.txt"
local data = game:HttpGet(url, true)
local myId = tostring(game.Players.LocalPlayer.UserId)

if data:find(myId) then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/vixsur737/Crasher/refs/heads/main/Crasher.lua", true))()
else
    game.Players.LocalPlayer:Kick("Вас нету в Вайт листе")
end
