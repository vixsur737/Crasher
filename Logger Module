-- Logger.lua
local Logger = {}

Logger.Config = {
    LogsURL = "https://ваш-сервер.com/logs",
    EnableConsoleLogs = true,
    EnableServerLogs = false
}

function Logger:SendLog(action, data)
    local logData = {
        action = action,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        player = game.Players.LocalPlayer.Name,
        userId = game.Players.LocalPlayer.UserId,
        additionalData = data
    }
    
    -- Логи в консоль
    if self.Config.EnableConsoleLogs then
        print("[Whitelist System]: " .. action)
        print("Player:", logData.player)
        print("User ID:", logData.userId)
        if data then
            for k, v in pairs(data) do
                print(k .. ":", v)
            end
        end
        print("---")
    end
    
    -- Отправка на сервер
    if self.Config.EnableServerLogs and self.Config.LogsURL then
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local json = HttpService:JSONEncode(logData)
            -- Здесь ваш POST запрос
        end)
    end
    
    return logData
end

return Logger
