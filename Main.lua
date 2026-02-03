-- Main.lua
local Logger = https://github.com/vixsur737/Crasher/blob/main/Logger.lua
local InjectorChecker = https://github.com/vixsur737/Crasher/blob/main/InjectorChecker.lua
local WhitelistChecker = https://raw.githubusercontent.com/vixsur737/Crasher/main/WhitelistChecker.lua

local MainSystem = {}

MainSystem.Config = {
    MainScriptURL = "https://raw.githubusercontent.com/vixsur737/Crasher/refs/heads/main/Crasher.lua",
    KickMessage = "Вас нету в Вайт листе",
    AllowedInjectors = {"Synapse X", "KRNL", "ScriptWare", "Xeno", "Vulcan", "Oxygen U"},
    StrictMode = false -- true = проверять все условия, false = достаточно одного совпадения
}

function MainSystem:CreateFakeKick(message)
    local player = game.Players.LocalPlayer
    
    -- Создаем GUI для фейк-кика
    local gui = Instance.new("ScreenGui")
    gui.Name = "FakeKickGui"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.Parent = gui
    
    -- Текст кика
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
    textLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message or self.Config.KickMessage
    textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    textLabel.TextSize = 24
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextWrapped = true
    textLabel.Parent = frame
    
    -- Дополнительная информация
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    infoLabel.Position = UDim2.new(0.1, 0, 0.7, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Error Code: 267\nPlease contact support"
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextSize = 16
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.Parent = frame
    
    -- Эффект затемнения
    for i = 1, 20 do
        frame.BackgroundTransparency = frame.BackgroundTransparency - 0.05
        wait(0.01)
    end
    
    -- Симуляция задержки и "краша"
    wait(2)
    
    -- Бесконечный цикл для симуляции краша
    while true do
        wait(1)
        -- Можно добавить дополнительные эффекты
    end
end

function MainSystem:Start()
    -- Логирование начала проверки
    Logger:SendLog("SYSTEM_START", {
        player = game.Players.LocalPlayer.Name,
        userId = game.Players.LocalPlayer.UserId
    })
    
    -- Получаем информацию об инжекторе
    local injectorInfo = InjectorChecker:GetInjectorInfo()
    
    Logger:SendLog("INJECTOR_INFO", {
        name = injectorInfo.name,
        version = injectorInfo.version or "Unknown",
        deviceId = injectorInfo.deviceId
    })
    
    -- Проверка разрешенного инжектора
    local isInjectorAllowed = InjectorChecker:IsAllowedInjector(MainSystem.Config.AllowedInjectors)
    
    if not isInjectorAllowed then
        Logger:SendLog("INJECTOR_NOT_ALLOWED", {
            injector = injectorInfo.name,
            allowed = MainSystem.Config.AllowedInjectors
        })
        
        MainSystem:CreateFakeKick("Invalid executor detected: " .. injectorInfo.name)
        return
    end
    
    -- Проверка вайт-листа
    local playerId = game.Players.LocalPlayer.UserId
    local isWhitelisted, reason = WhitelistChecker:CheckUser(
        playerId,
        injectorInfo.deviceId,
        injectorInfo.name
    )
    
    Logger:SendLog("WHITELIST_CHECK", {
        result = isWhitelisted,
        reason = reason,
        userId = playerId,
        deviceId = injectorInfo.deviceId,
        injector = injectorInfo.name
    })
    
    if isWhitelisted then
        -- Загрузка основного скрипта
        Logger:SendLog("LOADING_MAIN_SCRIPT", {})
        
        local success, mainScript = pcall(function()
            return game:HttpGet(MainSystem.Config.MainScriptURL, true)
        end)
        
        if success and mainScript then
            Logger:SendLog("SCRIPT_LOAD_SUCCESS", {})
            loadstring(mainScript)()
        else
            Logger:SendLog("SCRIPT_LOAD_FAILED", {error = mainScript})
            MainSystem:CreateFakeKick("Failed to load main script")
        end
    else
        -- Кик если не в вайт-листе
        Logger:SendLog("KICK_PLAYER", {
            reason = reason,
            userId = playerId
        })
        
        MainSystem:CreateFakeKick(MainSystem.Config.KickMessage)
    end
end

-- Автозапуск
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Ждем загрузки игрока
if not game.Players.LocalPlayer then
    game.Players:WaitForChild(game.Players.LocalPlayer.Name)
end

-- Запускаем систему
MainSystem:Start()

return MainSystem
