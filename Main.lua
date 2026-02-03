-- Whitelist System - Complete Monolithic Version
-- Вставьте этот код и он будет работать как один файл

-- ===== КОНФИГУРАЦИЯ =====
local CONFIG = {
    WhitelistURL = "https://github.com/vixsur737/Crasher/blob/main/Whitelist.txt", -- Замените на ваш вайт-лист
    MainScriptURL = "https://raw.githubusercontent.com/vixsur737/Crasher/refs/heads/main/Crasher.lua",
    KickMessage = "Вас нету в Вайт листе",
    ErrorMessage = "Ошибка проверки вайт-листа",
    StrictMode = false
}

-- ===== ЛОГГЕР =====
local Logger = {
    logs = {}
}

function Logger:log(action, data)
    local logEntry = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        action = action,
        player = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown",
        userId = game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0,
        data = data or {}
    }
    
    table.insert(self.logs, logEntry)
    
    print("[Whitelist] " .. action)
    if data then
        for k, v in pairs(data) do
            print("  " .. k .. ": " .. tostring(v))
        end
    end
    print("---")
    
    return logEntry
end

-- ===== ДЕТЕКЦИЯ ИНЖЕКТОРА =====
local InjectorDetector = {}

function InjectorDetector:detect()
    local injectorInfo = {
        name = "Unknown",
        deviceId = self:generateDeviceId()
    }
    
    -- Проверка Synapse X
    if syn and syn.request then
        injectorInfo.name = "Synapse X"
    end
    
    -- Проверка KRNL
    if KRNL_LOADED or (identifyexecutor and identifyexecutor():lower():find("krnl")) then
        injectorInfo.name = "KRNL"
    end
    
    -- Проверка ScriptWare
    if SW_LOADED then
        injectorInfo.name = "ScriptWare"
    end
    
    -- Проверка Fluxus
    if FLUXUS_LOADED then
        injectorInfo.name = "Fluxus"
    end
    
    -- Проверка Comet
    if COMET_LOADED then
        injectorInfo.name = "Comet"
    end
    
    -- Проверка Xeno
    if is_xeno or (getgenv and (getgenv().Xeno or getgenv().XenoExec)) then
        injectorInfo.name = "Xeno"
    end
    
    -- Проверка Vulcan
    if is_vulcan or (getgenv and (getgenv().Vulcan or getgenv().VulcanExec)) then
        injectorInfo.name = "Vulcan"
    end
    
    -- Проверка Oxygen U
    if is_oxygen or (getgenv and (getgenv().Oxygen or getgenv().OxygenU)) then
        injectorInfo.name = "Oxygen U"
    end
    
    -- Проверка через identifyexecutor (универсальный метод)
    if identifyexecutor then
        local execName = identifyexecutor():lower()
        if execName:find("xeno") then injectorInfo.name = "Xeno"
        elseif execName:find("vulcan") then injectorInfo.name = "Vulcan"
        elseif execName:find("oxygen") then injectorInfo.name = "Oxygen U"
        elseif execName:find("synapse") then injectorInfo.name = "Synapse X"
        elseif execName:find("krnl") then injectorInfo.name = "KRNL"
        elseif execName:find("scriptware") then injectorInfo.name = "ScriptWare"
        elseif execName:find("fluxus") then injectorInfo.name = "Fluxus"
        elseif execName:find("comet") then injectorInfo.name = "Comet"
        end
    end
    
    Logger:log("INJECTOR_DETECTED", {
        name = injectorInfo.name,
        deviceId = injectorInfo.deviceId
    })
    
    return injectorInfo
end

function InjectorDetector:generateDeviceId()
    local deviceId = ""
    
    -- Пробуем разные методы получения уникального ID
    local methods = {
        function() 
            local success, result = pcall(function()
                return game:GetService("RbxAnalyticsService"):GetClientId()
            end)
            return success and result or nil
        end,
        function()
            return tostring(tick()) .. tostring(math.random(10000, 99999))
        end,
        function()
            return tostring(os.time()) .. "_" .. tostring(os.clock())
        end
    }
    
    for _, method in ipairs(methods) do
        local result = method()
        if result then
            deviceId = tostring(result)
            break
        end
    end
    
    -- Если ничего не получилось, создаем простой ID
    if deviceId == "" then
        deviceId = "DEV_" .. tostring(math.random(100000, 999999))
    end
    
    return deviceId
end

-- ===== ЗАГРУЗЧИК ВАЙТ-ЛИСТА =====
local WhitelistLoader = {
    cache = nil,
    lastLoad = 0
}

function WhitelistLoader:load()
    -- Кеширование на 30 секунд
    if self.cache and (tick() - self.lastLoad) < 30 then
        Logger:log("WHITELIST_CACHE_USED", {})
        return self.cache
    end
    
    Logger:log("WHITELIST_LOADING", {url = CONFIG.WhitelistURL})
    
    local success, result = pcall(function()
        return game:HttpGet(CONFIG.WhitelistURL, true)
    end)
    
    if not success then
        Logger:log("WHITELIST_LOAD_ERROR", {error = result})
        return nil
    end
    
    -- Парсинг вайт-листа
    local whitelist = {
        users = {},      -- user_id -> true
        devices = {},    -- device_id -> true
        injectors = {},  -- injector_name -> true
        combos = {}      -- полные записи
    }
    
    for line in result:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- обрезаем пробелы
        
        if line ~= "" and not line:startswith("#") then
            -- Формат 1: Просто user_id
            if line:match("^%d+$") then
                whitelist.users[line] = true
            -- Формат 2: injector|device|user
            elseif line:find("|") then
                local parts = {}
                for part in line:gmatch("[^|]+") do
                    table.insert(parts, part)
                end
                
                if #parts >= 2 then
                    local entry = {
                        injector = parts[1] ~= "*" and parts[1] or nil,
                        device = parts[2] ~= "*" and parts[2] or nil,
                        user = parts[3] ~= "*" and parts[3] or nil
                    }
                    
                    table.insert(whitelist.combos, entry)
                    
                    -- Добавляем в быстрые списки
                    if entry.user then whitelist.users[entry.user] = true end
                    if entry.device then whitelist.devices[entry.device] = true end
                    if entry.injector then whitelist.injectors[entry.injector] = true end
                end
            end
        end
    end
    
    self.cache = whitelist
    self.lastLoad = tick()
    
    Logger:log("WHITELIST_LOADED", {
        users = table.count(whitelist.users),
        devices = table.count(whitelist.devices),
        injectors = table.count(whitelist.injectors),
        combos = #whitelist.combos
    })
    
    return whitelist
end

-- ===== ПРОВЕРКА ВАЙТ-ЛИСТА =====
local WhitelistChecker = {}

function WhitelistChecker:check(userId, deviceId, injectorName)
    Logger:log("WHITELIST_CHECK_START", {
        userId = userId,
        deviceId = deviceId,
        injector = injectorName
    })
    
    local whitelist = WhitelistLoader:load()
    if not whitelist then
        return false, "Не удалось загрузить вайт-лист"
    end
    
    local userIdStr = tostring(userId)
    local injectorLower = injectorName and injectorName:lower() or ""
    
    -- Быстрая проверка по user_id
    if whitelist.users[userIdStr] then
        Logger:log("WHITELIST_CHECK_PASS_USER", {userId = userId})
        return true, "User ID в вайт-листе"
    end
    
    -- Проверка по device_id
    if deviceId and whitelist.devices[deviceId] then
        Logger:log("WHITELIST_CHECK_PASS_DEVICE", {deviceId = deviceId})
        return true, "Device ID в вайт-листе"
    end
    
    -- Проверка по инжектору
    if injectorName and whitelist.injectors[injectorName] then
        Logger:log("WHITELIST_CHECK_PASS_INJECTOR", {injector = injectorName})
        return true, "Инжектор в вайт-листе"
    end
    
    -- Проверка полных комбинаций
    for _, entry in ipairs(whitelist.combos) do
        local injectorMatch = not entry.injector or entry.injector:lower() == injectorLower
        local deviceMatch = not entry.device or entry.device == deviceId
        local userMatch = not entry.user or entry.user == userIdStr
        
        if injectorMatch and deviceMatch and userMatch then
            Logger:log("WHITELIST_CHECK_PASS_COMBO", {
                injector = entry.injector,
                device = entry.device,
                user = entry.user
            })
            return true, "Полное совпадение в вайт-листе"
        end
    end
    
    Logger:log("WHITELIST_CHECK_FAIL", {
        reason = "Не найден в вайт-листе"
    })
    
    return false, "Не найден в вайт-листе"
end

-- ===== ФЕЙК КИК =====
local function createFakeKick(message)
    Logger:log("CREATING_FAKE_KICK", {message = message})
    
    -- Удаляем старый GUI если есть
    pcall(function()
        local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("FakeKickGui")
        if gui then gui:Destroy() end
    end)
    
    -- Создаем новый GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "FakeKickGui"
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
    messageLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message or CONFIG.KickMessage
    messageLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    messageLabel.TextSize = 24
    messageLabel.Font = Enum.Font.SourceSansBold
    messageLabel.TextWrapped = true
    messageLabel.Parent = frame
    
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    errorLabel.Position = UDim2.new(0.1, 0, 0.7, 0)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = "Error Code: 267\nPlease try again later"
    errorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    errorLabel.TextSize = 16
    errorLabel.Font = Enum.Font.SourceSans
    errorLabel.TextWrapped = true
    errorLabel.Parent = frame
    
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Эффект появления
    frame.BackgroundTransparency = 1
    for i = 1, 20 do
        frame.BackgroundTransparency = frame.BackgroundTransparency - 0.05
        wait(0.01)
    end
    
    -- Ждем 3 секунды
    wait(3)
    
    -- Симуляция краша через бесконечный цикл
    while true do
        wait(1)
    end
end

-- ===== ЗАГРУЗКА ОСНОВНОГО СКРИПТА =====
local function loadMainScript()
    Logger:log("LOADING_MAIN_SCRIPT", {url = CONFIG.MainScriptURL})
    
    local success, scriptContent = pcall(function()
        return game:HttpGet(CONFIG.MainScriptURL, true)
    end)
    
    if not success then
        Logger:log("MAIN_SCRIPT_LOAD_ERROR", {error = scriptContent})
        createFakeKick("Ошибка загрузки скрипта")
        return false
    end
    
    Logger:log("MAIN_SCRIPT_LOADED", {size = #scriptContent})
    
    local success2, error = pcall(function()
        loadstring(scriptContent)()
    end)
    
    if not success2 then
        Logger:log("MAIN_SCRIPT_EXECUTE_ERROR", {error = error})
        createFakeKick("Ошибка выполнения скрипта")
        return false
    end
    
    Logger:log("MAIN_SCRIPT_EXECUTED", {})
    return true
end

-- ===== ОСНОВНАЯ ФУНКЦИЯ =====
local function main()
    Logger:log("SYSTEM_START", {})
    
    -- Ждем загрузки игры и игрока
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    if not game.Players.LocalPlayer then
        game.Players.PlayerAdded:Wait()
    end
    
    Logger:log("PLAYER_LOADED", {
        name = game.Players.LocalPlayer.Name,
        userId = game.Players.LocalPlayer.UserId
    })
    
    -- Обнаруживаем инжектор
    local injectorInfo = InjectorDetector:detect()
    
    -- Получаем данные игрока
    local userId = game.Players.LocalPlayer.UserId
    local deviceId = injectorInfo.deviceId
    local injectorName = injectorInfo.name
    
    -- Проверяем вайт-лист
    local isWhitelisted, reason = WhitelistChecker:check(userId, deviceId, injectorName)
    
    if isWhitelisted then
        Logger:log("ACCESS_GRANTED", {reason = reason})
        
        -- Загружаем основной скрипт
        local success = loadMainScript()
        if not success then
            createFakeKick("Ошибка загрузки основного скрипта")
        end
    else
        Logger:log("ACCESS_DENIED", {reason = reason})
        
        -- Кикаем игрока
        createFakeKick(CONFIG.KickMessage)
    end
end

-- ===== ЗАПУСК СИСТЕМЫ =====
-- Запускаем с обработкой ошибок
local success, error = pcall(main)

if not success then
    print("[Whitelist System] Critical Error: " .. tostring(error))
    print("[Whitelist System] Creating fake kick...")
    
    -- При критической ошибке тоже кикаем
    pcall(function()
        createFakeKick("Системная ошибка")
    end)
end
