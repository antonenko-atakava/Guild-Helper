--- Модуль системы уведомлений
-- @module modules.notifications

local config = GuildHelperConfig
local MESSAGE_DELAY = config.CONSTANTS.MESSAGE_DELAY

-- Локализация глобальных функций
local SendChatMessage = SendChatMessage
local PlaySound = PlaySound
local GetTime = GetTime
local tinsert = table.insert
local tremove = table.remove
local string_format = string.format

-- Локальные переменные
local message_queue = {}
local is_processing_queue = false
local last_message_time = 0
local notification_frame = CreateFrame("Frame")

--- Добавляет сообщение в очередь отправки
-- @param name string Имя получателя
-- @param message string Текст сообщения
local function AddToQueue(name, message)
    tinsert(message_queue, {name = name, message = message})
    
    if not is_processing_queue then
        is_processing_queue = true
        notification_frame:SetScript("OnUpdate", ProcessMessageQueue)
    end
end

--- Обрабатывает очередь сообщений
-- @param self frame Фрейм обработчика
-- @param elapsed number Прошедшее время
function ProcessMessageQueue(self, elapsed)
    last_message_time = last_message_time + elapsed
    
    if last_message_time >= MESSAGE_DELAY and #message_queue > 0 then
        local msg = tremove(message_queue, 1)
        SendChatMessage(msg.message, "WHISPER", nil, msg.name)
        
        local remaining = #message_queue
        print(string_format("|cFF00FF00[GuildHelper]|r Отправлено сообщение игроку |cFFFFFF00%s|r |cFF808080(осталось: %d)|r", msg.name, remaining))
        
        if GuildHelperChatLog then
            GuildHelperChatLog.AddMessage(string_format("-> %s (осталось: %d)", msg.name, remaining))
        end
        
        last_message_time = 0
        
        -- Обновление UI
        if GuildHelperUI then
            GuildHelperUI.UpdateNotificationStatus()
        end
    end
    
    if #message_queue == 0 then
        is_processing_queue = false
        self:SetScript("OnUpdate", nil)
        print("|cFF00FF00[GuildHelper]|r Все уведомления отправлены!")
        
        if GuildHelperChatLog then
            GuildHelperChatLog.AddMessage("=== Отправка завершена ===")
        end
        
        PlaySound("LevelUp")
        
        if GuildHelperUI then
            GuildHelperUI.UpdateNotificationStatus()
        end
    end
end

--- Отправляет уведомления всем игрокам из списка
-- @param members table Список членов гильдии
-- @param message string Текст уведомления
-- @return number Количество отправленных уведомлений
local function SendNotifications(members, message)
    if not members or #members == 0 then
        print("|cFFFF0000[GuildHelper]|r Нет данных для отправки уведомлений!")
        return 0
    end
    
    local online_count = 0
    
    -- Подсчет онлайн игроков
    for _, member in ipairs(members) do
        if member.isOnline then
            online_count = online_count + 1
        end
    end
    
    if online_count == 0 then
        print("|cFFFFAA00[GuildHelper]|r Нет игроков онлайн без заметок.")
        return 0
    end
    
    -- Подтверждение отправки
    print(string_format("|cFFFFFF00[GuildHelper]|r Будет отправлено %d уведомлений. Время: ~%d сек.", online_count, online_count * MESSAGE_DELAY))
    print("|cFF00FF00[GuildHelper]|r Начинаю отправку...")
    PlaySound("igMainMenuOpen")
    
    -- Добавление в очередь
    for _, member in ipairs(members) do
        if member.isOnline then
            AddToQueue(member.name, message)
        end
    end
    
    if GuildHelperChatLog then
        GuildHelperChatLog.AddMessage(string_format("=== Отправка уведомлений: %d игроков ===", online_count))
        GuildHelperChatLog.AddMessage(string_format("Время ожидания: ~%d секунд", online_count * MESSAGE_DELAY))
    end
    
    return online_count
end

--- Получает размер очереди сообщений
-- @return number Количество сообщений в очереди
local function GetQueueSize()
    return #message_queue
end

--- Проверяет, идет ли обработка очереди
-- @return boolean Статус обработки
local function IsProcessing()
    return is_processing_queue
end

--- Экспорт функций модуля
_G.GuildHelperNotifications = {
    SendNotifications = SendNotifications,
    GetQueueSize = GetQueueSize,
    IsProcessing = IsProcessing,
}

