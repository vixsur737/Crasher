-- WhitelistChecker.lua
local WhitelistChecker = {}

WhitelistChecker.Config = {
    WhitelistURL = "https://github.com/vixsur737/Crasher/blob/main/Whitelist.txt",
    CacheTime = 60 -- Кеширование на 60 секунд
}

WhitelistChecker.Cache = {
    data = nil,
    timestamp = 0
}

function WhitelistChecker:LoadWhitelist()
    -- Проверка кеша
    local now = tick()
    if self.Cache.data and (now - self.Cache.timestamp) < self.Config.CacheTime then
        return self.Cache.data
    end
    
    local success, whitelistData = pcall(function()
        return game:HttpGet(self.Config.WhitelistURL, true)
    end)
    
    if not success then
        return nil, "Failed to load whitelist: " .. tostring(whitelistData)
    end
    
    -- Парсинг вайт-листа
    local whitelist = {
        users = {},    -- по user_id
        devices = {},  -- по device_id
        injectors = {}, -- по инжекторам
        combos = {}    -- комбинированные записи
    }
    
    for line in whitelistData:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- trim
        
        if line ~= "" and not line:find("^#") then -- игнорируем пустые строки и комментарии
            -- Формат 1: user_id (только ID пользователя)
            if line:match("^%d+$") then
                whitelist.users[line] = true
            
            -- Формат 2: injector:device_id:user_id
            elseif line:match(":") then
                local parts = {}
                for part in line:gmatch("[^:]+") do
                    table.insert(parts, part)
                end
                
                if #parts >= 2 then
                    local entry = {
                        injector = parts[1] ~= "*" and parts[1] or nil,
                        deviceId = parts[2] ~= "*" and parts[2] or nil,
                        userId = parts[3] ~= "*" and parts[3] or nil
                    }
                    
                    table.insert(whitelist.combos, entry)
                    
                    -- Добавляем в отдельные списки для быстрого поиска
                    if entry.userId then
                        whitelist.users[entry.userId] = true
                    end
                    if entry.deviceId then
                        whitelist.devices[entry.deviceId] = true
                    end
                    if entry.injector then
                        whitelist.injectors[entry.injector:lower()] = true
                    end
                end
            end
        end
    end
    
    -- Кешируем
    self.Cache.data = whitelist
    self.Cache.timestamp = now
    
    return whitelist
end

function WhitelistChecker:CheckUser(userId, deviceId, injectorName)
    local whitelist, error = self:LoadWhitelist()
    if not whitelist then
        return false, error or "Whitelist not loaded"
    end
    
    local userIdStr = tostring(userId)
    local injectorLower = injectorName and injectorName:lower() or ""
    
    -- Быстрые проверки по отдельным категориям
    if whitelist.users[userIdStr] then
        return true, "User ID in whitelist"
    end
    
    if deviceId and whitelist.devices[deviceId] then
        return true, "Device ID in whitelist"
    end
    
    if injectorName and whitelist.injectors[injectorLower] then
        return true, "Injector in whitelist"
    end
    
    -- Проверка комбинированных записей
    for _, entry in ipairs(whitelist.combos) do
        local injectorMatch = not entry.injector or entry.injector:lower() == injectorLower
        local deviceMatch = not entry.deviceId or entry.deviceId == deviceId
        local userMatch = not entry.userId or entry.userId == userIdStr
        
        if injectorMatch and deviceMatch and userMatch then
            return true, "Combo match in whitelist"
        end
    end
    
    return false, "Not in whitelist"
end

function WhitelistChecker:GetWhitelistInfo()
    local whitelist = self:LoadWhitelist()
    if not whitelist then
        return "Whitelist not loaded"
    end
    
    local info = {
        totalUsers = 0,
        totalDevices = 0,
        totalInjectors = 0,
        totalCombos = #whitelist.combos
    }
    
    for _ in pairs(whitelist.users) do info.totalUsers = info.totalUsers + 1 end
    for _ in pairs(whitelist.devices) do info.totalDevices = info.totalDevices + 1 end
    for _ in pairs(whitelist.injectors) do info.totalInjectors = info.totalInjectors + 1 end
    
    return info
end

return WhitelistChecker
