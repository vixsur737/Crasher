-- InjectorChecker.lua
local InjectorChecker = {}

InjectorChecker.Injectors = {
    ["Synapse X"] = function()
        return syn and syn.request and not is_sirhurt_closure and (identifyexecutor and identifyexecutor() == "Synapse X")
    end,
    
    ["KRNL"] = function()
        return KRNL_LOADED or (identifyexecutor and identifyexecutor():lower():find("krnl"))
    end,
    
    ["ScriptWare"] = function()
        return SW_LOADED or (identifyexecutor and identifyexecutor():lower():find("scriptware"))
    end,
    
    ["Fluxus"] = function()
        return FLUXUS_LOADED or (identifyexecutor and identifyexecutor():lower():find("fluxus"))
    end,
    
    ["Comet"] = function()
        return COMET_LOADED or (identifyexecutor and identifyexecutor():lower():find("comet"))
    end,
    
    ["Xeno"] = function()
        -- Проверка для Xeno
        if is_xeno then
            return true
        end
        if getgenv then
            local env = getgenv()
            if env.Xeno or env.XenoExec then
                return true
            end
        end
        if identifyexecutor then
            local name = identifyexecutor():lower()
            return name:find("xeno") ~= nil
        end
        return false
    end,
    
    ["Vulcan"] = function()
        -- Проверка для Vulcan
        if is_vulcan then
            return true
        end
        if getgenv then
            local env = getgenv()
            if env.Vulcan or env.VulcanExec then
                return true
            end
        end
        if identifyexecutor then
            local name = identifyexecutor():lower()
            return name:find("vulcan") ~= nil
        end
        return false
    end,
    
    ["Oxygen U"] = function()
        -- Проверка для Oxygen U
        if is_oxygen then
            return true
        end
        if getgenv then
            local env = getgenv()
            if env.Oxygen or env.OxygenU then
                return true
            end
        end
        if identifyexecutor then
            local name = identifyexecutor():lower()
            return name:find("oxygen") ~= nil or name:find("oxygen u") ~= nil
        end
        return false
    end,
    
    ["Unknown"] = function()
        return true -- Всегда true, если не определено
    end
}

function InjectorChecker:GetInjectorInfo()
    local injectorInfo = {
        name = "Unknown",
        version = "Unknown",
        deviceId = self:GenerateDeviceID()
    }
    
    -- Проверяем каждый инжектор
    for injectorName, checkFunction in pairs(self.Injectors) do
        if injectorName ~= "Unknown" then
            local success, result = pcall(checkFunction)
            if success and result == true then
                injectorInfo.name = injectorName
                break
            end
        end
    end
    
    -- Получаем версию инжектора если возможно
    pcall(function()
        if getexecutorname then
            injectorInfo.name = getexecutorname()
        end
        if identifyexecutor then
            injectorInfo.name = identifyexecutor()
        end
        if getexecutorversion then
            injectorInfo.version = getexecutorversion()
        end
    end)
    
    return injectorInfo
end

function InjectorChecker:GenerateDeviceID()
    local deviceId = ""
    
    -- Пытаемся получить уникальный ID несколькими способами
    local methods = {
        function() return game:GetService("RbxAnalyticsService"):GetClientId() end,
        function() return game:GetService("Players").LocalPlayer.UserId end,
        function() return tostring(tick()) .. tostring(math.random(10000, 99999)) end,
        function() return tostring(os.time()) .. tostring(os.clock()) end
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            deviceId = tostring(result)
            break
        end
    end
    
    -- Хешируем для дополнительной уникальности
    if deviceId ~= "" then
        local hash = 0
        for i = 1, #deviceId do
            hash = (hash * 31 + string.byte(deviceId, i)) % 2^32
        end
        deviceId = "DEV_" .. tostring(hash)
    else
        deviceId = "DEV_" .. tostring(math.random(100000, 999999))
    end
    
    return deviceId
end

function InjectorChecker:IsAllowedInjector(allowedInjectors)
    local injectorInfo = self:GetInjectorInfo()
    
    if not allowedInjectors or #allowedInjectors == 0 then
        return true -- Если нет ограничений
    end
    
    for _, allowed in ipairs(allowedInjectors) do
        if injectorInfo.name:lower():find(allowed:lower()) or allowed:lower() == "all" then
            return true
        end
    end
    
    return false
end

return InjectorChecker
