-- Ultra Simple Whitelist System
-- Эта версия точно должна работать

local WhitelistURL = "https://github.com/vixsur737/Crasher/blob/main/Whitelist.txt" -- ВАШ ВАЙТ-ЛИСТ

-- Функция для красивого кика
function KickPlayer(reason)
    reason = reason or "Вас нету в Вайт листе"
    
    -- Простой кик
    game.Players.LocalPlayer:Kick(reason)
    
    -- Дополнительно: симуляция краша
    while true do
        wait(1)
    end
end

-- Функция получения User ID
function GetMyUserId()
    if game.Players.LocalPlayer then
        return tostring(game.Players.LocalPlayer.UserId)
    end
    return "0"
end

-- Основная проверка
function Main()
    print("[Whitelist] Starting check...")
    
    -- Ждем загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Ждем игрока
    while not game.Players.LocalPlayer do
        wait(0.1)
    end
    
    local myUserId = GetMyUserId()
    print("[Whitelist] My User ID:", myUserId)
    
    -- Загружаем вайт-лист
    local success, whitelistData = pcall(function()
        return game:HttpGet(WhitelistURL, true)
    end)
    
    if not success then
        print("[Whitelist] ERROR: Can't load whitelist")
        KickPlayer("Ошибка загрузки вайт-листа")
        return
    end
    
    -- Проверяем наличие нашего ID в вайт-листе
    local found = false
    
    for line in whitelistData:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- Убираем пробелы
        
        if line ~= "" and not line:find("^#") then
            -- Игнорируем комментарии
            if line == "*" then
                found = true
                break
            elseif line == myUserId then
                found = true
                break
            elseif line:find(":") then
                local parts = {}
                for part in line:gmatch("[^:]+") do
                    table.insert(parts, part)
                end
                if #parts >= 2 and (parts[2] == "*" or parts[2] == myUserId) then
                    found = true
                    break
                end
            end
        end
    end
    
    if found then
        print("[Whitelist] Access GRANTED!")
        
        -- Загружаем основной скрипт
        local scriptSuccess, mainScript = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/vixsur737/Crasher/refs/heads/main/Crasher.lua", true)
        end)
        
        if scriptSuccess and mainScript then
            loadstring(mainScript)()
        else
            print("[Whitelist] ERROR: Can't load main script")
            KickPlayer("Ошибка загрузки скрипта")
        end
    else
        print("[Whitelist] Access DENIED!")
        KickPlayer("Вас нету в Вайт листе")
    end
end

-- Запускаем с защитой от ошибок
local success, err = pcall(Main)
if not success then
    print("[Whitelist] FATAL ERROR:", err)
    -- Даже при ошибке кикаем
    if game.Players.LocalPlayer then
        game.Players.LocalPlayer:Kick("Системная ошибка")
    end
end
