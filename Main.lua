-- Whitelist System - Fixed Version
-- Полный рабочий скрипт с правильным киком

-- ===== КОНФИГУРАЦИЯ =====
local CONFIG = {
    WhitelistURL = "https://github.com/vixsur737/Crasher/blob/main/Whitelist.txt", -- Замените на ссылку на ваш вайт-лист
    MainScriptURL = "https://raw.githubusercontent.com/vixsur737/Crasher/refs/heads/main/Crasher.lua",
    KickMessage = "Вас нету в Вайт листе",
    ErrorMessage = "Ошибка проверки вайт-листа"
}

-- ===== ОСНОВНАЯ ФУНКЦИЯ КИКА =====
local function createFakeKick(reason)
    reason = reason or CONFIG.KickMessage
    
    -- 1. Сначала создаем фейковую ошибку в консоли (это видно только во вкладке Output)
    print("")
    print("══════════════════════════════════════════════════")
    print("               Roblox Error Report               ")
    print("══════════════════════════════════════════════════")
    print("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    print("Player: " .. game.Players.LocalPlayer.Name)
    print("User ID: " .. game.Players.LocalPlayer.UserId)
    print("Error: " .. reason)
    print("Error Code: 267")
    print("Stack Trace: AccessDeniedException")
    print("══════════════════════════════════════════════════")
    print("")
    
    -- 2. Создаем реальный кик, который выглядит как системная ошибка
    -- Это вызовет стандартное окно кика Roblox
    game.Players.LocalPlayer:Kick("\n\n══════════════════════════════════════════════════\n" ..
                                  "               ROBLOX ERROR REPORT               \n" ..
                                  "══════════════════════════════════════════════════\n\n" ..
                                  "ERROR: " .. reason .. "\n\n" ..
                                  "Error Code: 267\n" ..
                                  "Player: " .. game.Players.LocalPlayer.Name .. "\n" ..
                                  "User ID: " .. game.Players.LocalPlayer.UserId .. "\n\n" ..
                                  "══════════════════════════════════════════════════\n" ..
                                  "Please contact support if this error persists.\n")
    
    -- 3. Альтернативный метод для некоторых инжекторов
    wait(0.1)
    
    -- Симуляция краша игры через бесконечный цикл
    while true do
        -- Можно добавить визуальные эффекты
        game:GetService("RunService").RenderStepped:Wait()
    end
end

-- ===== ДЕТЕКЦИЯ ИНЖЕКТОРА =====
local function detectInjector()
    local injectorInfo = {
        name = "Unknown",
        deviceId = ""
    }
    
    -- Простые проверки для популярных инжекторов
    if syn and syn.request then
        injectorInfo.name = "Synapse X"
    elseif KRNL_LOADED then
        injectorInfo.name = "KRNL"
    elseif identifyexecutor then
        local exec = identifyexecutor()
        if exec:lower():find("xeno") then
            injectorInfo.name = "Xeno"
        elseif exec:lower():find("vulcan") then
            injectorInfo.name = "Vulcan"
        elseif exec:lower():find("oxygen") then
            injectorInfo.name = "Oxygen U"
        elseif exec:lower():find("scriptware") then
            injectorInfo.name = "ScriptWare"
        elseif exec:lower():find("fluxus") then
            injectorInfo.name = "Fluxus"
        else
            injectorInfo.name = exec
        end
    elseif getgenv and (getgenv().Xeno or getgenv().XenoExec) then
        injectorInfo.name = "Xeno"
    elseif getgenv and (getgenv().Vulcan or getgenv().VulcanExec) then
        injectorInfo.name = "Vulcan"
    elseif getgenv and (getgenv().Oxygen or getgenv().OxygenU) then
        injectorInfo.name = "Oxygen U"
    end
    
    -- Генерация device ID
    local deviceId = tostring(game.Players.LocalPlayer.UserId) .. "_" .. tostring(math.random(10000, 99999))
    injectorInfo.deviceId = deviceId
    
    print("[Whitelist] Injector detected: " .. injectorInfo.name)
    print("[Whitelist] Device ID: " .. deviceId)
    
    return injectorInfo
end

-- ===== ЗАГРУЗКА ВАЙТ-ЛИСТА =====
local function loadWhitelist()
    print("[Whitelist] Loading whitelist from: " .. CONFIG.WhitelistURL)
    
    local success, result = pcall(function()
        return game:HttpGet(CONFIG.WhitelistURL, true)
    end)
    
    if not success then
        print("[Whitelist] ERROR: Failed to load whitelist - " .. tostring(result))
        return nil
    end
    
    -- Простой парсинг
    local whitelist = {}
    for line in result:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- обрезаем пробелы
        
        if line ~= "" and not line:find("^#") then
            -- Форматы: userId или injector:userId или *
            if line == "*" then
                table.insert(whitelist, {type = "all"})
            elseif line:find(":") then
                local parts = {}
                for part in line:gmatch("[^:]+") do
                    table.insert(parts, part)
                end
                if #parts >= 2 then
                    table.insert(whitelist, {
                        type = "combo",
                        injector = parts[1],
                        userId = parts[2]
                    })
                end
            else
                table.insert(whitelist, {
                    type = "user",
                    userId = line
                })
            end
        end
    end
    
    print("[Whitelist] Whitelist loaded: " .. #whitelist .. " entries")
    return whitelist
end

-- ===== ПРОВЕРКА ВАЙТ-ЛИСТА =====
local function checkWhitelist(injectorInfo)
    local whitelist = loadWhitelist()
    if not whitelist then
        return false, "Не удалось загрузить вайт-лист"
    end
    
    local userId = tostring(game.Players.LocalPlayer.UserId)
    local injectorName = injectorInfo.name
    
    print("[Whitelist] Checking whitelist for:")
    print("[Whitelist]   User ID: " .. userId)
    print("[Whitelist]   Injector: " .. injectorName)
    
    -- Проверка каждой записи
    for _, entry in ipairs(whitelist) do
        if entry.type == "all" then
            print("[Whitelist]   Found: ALL (wildcard)")
            return true, "Все пользователи разрешены"
        
        elseif entry.type == "user" and entry.userId == userId then
            print("[Whitelist]   Found: User ID match")
            return true, "User ID найден в вайт-листе"
        
        elseif entry.type == "combo" then
            local injectorMatch = entry.injector == "*" or entry.injector == injectorName
            local userMatch = entry.userId == "*" or entry.userId == userId
            
            if injectorMatch and userMatch then
                print("[Whitelist]   Found: Combo match")
                return true, "Комбинация найдена в вайт-листе"
            end
        end
    end
    
    return false, "Не найден в вайт-листе"
end

-- ===== ЗАГРУЗКА ОСНОВНОГО СКРИПТА =====
local function loadMainScript()
    print("[Whitelist] Loading main script from: " .. CONFIG.MainScriptURL)
    
    local success, scriptContent = pcall(function()
        return game:HttpGet(CONFIG.MainScriptURL, true)
    end)
    
    if not success then
        print("[Whitelist] ERROR: Failed to load main script")
        createFakeKick("Ошибка загрузки основного скрипта")
        return false
    end
    
    -- Проверяем, что скрипт не пустой
    if #scriptContent < 10 then
        print("[Whitelist] ERROR: Main script is empty or too short")
        createFakeKick("Основной скрипт поврежден")
        return false
    end
    
    -- Выполняем скрипт
    local success2, errorMsg = pcall(function()
        loadstring(scriptContent)()
    end)
    
    if not success2 then
        print("[Whitelist] ERROR: Failed to execute main script: " .. tostring(errorMsg))
        createFakeKick("Ошибка выполнения скрипта")
        return false
    end
    
    print("[Whitelist] Main script loaded successfully")
    return true
end

-- ===== ОСНОВНАЯ ФУНКЦИЯ =====
local function main()
    print("")
    print("══════════════════════════════════════════════════")
    print("           WHITELIST SYSTEM STARTING             ")
    print("══════════════════════════════════════════════════")
    
    -- Ждем загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Ждем появления игрока
    while not game.Players.LocalPlayer do
        wait(0.1)
    end
    
    print("[Whitelist] Player: " .. game.Players.LocalPlayer.Name)
    print("[Whitelist] User ID: " .. game.Players.LocalPlayer.UserId)
    
    -- Обнаруживаем инжектор
    local injectorInfo = detectInjector()
    
    -- Проверяем вайт-лист
    local isWhitelisted, reason = checkWhitelist(injectorInfo)
    
    print("[Whitelist] Whitelist check result: " .. tostring(isWhitelisted))
    print("[Whitelist] Reason: " .. tostring(reason))
    
    if isWhitelisted then
        print("[Whitelist] Access GRANTED. Loading main script...")
        loadMainScript()
    else
        print("[Whitelist] Access DENIED. Kicking player...")
        createFakeKick(CONFIG.KickMessage)
    end
    
    print("══════════════════════════════════════════════════")
    print("")
end

-- ===== ЗАПУСК СИСТЕМЫ =====
-- Запускаем с обработкой ошибок
local success, errorMsg = pcall(main)

if not success then
    print("[Whitelist] CRITICAL ERROR: " .. tostring(errorMsg))
    print("[Whitelist] Creating emergency kick...")
    
    -- При критической ошибке тоже кикаем
    pcall(function()
        createFakeKick("Системная ошибка: " .. tostring(errorMsg))
    end)
end
