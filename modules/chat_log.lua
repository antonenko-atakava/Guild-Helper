--- Модуль журнала чата
-- @module modules.chat_log

-- Локализация глобальных функций
local tinsert = table.insert
local tconcat = table.concat

-- Локальные переменные
local chat_messages = {}

--- Добавляет сообщение в журнал
-- @param message string Текст сообщения
local function AddMessage(message)
    tinsert(chat_messages, message)
    
    -- Обновление окна чата, если оно открыто
    if GuildHelperUI and GuildHelperUI.UpdateChatWindow then
        GuildHelperUI.UpdateChatWindow()
    end
end

--- Очищает все сообщения в журнале
local function ClearMessages()
    chat_messages = {}
    
    if GuildHelperUI and GuildHelperUI.UpdateChatWindow then
        GuildHelperUI.UpdateChatWindow()
    end
end

--- Получает все сообщения из журнала
-- @return table Список сообщений
local function GetMessages()
    return chat_messages
end

--- Получает текст всех сообщений
-- @return string Объединенный текст
local function GetMessagesText()
    if #chat_messages == 0 then
        return "|cFF808080Нет сообщений...|r"
    end
    
    return tconcat(chat_messages, "\n")
end

--- Экспортирует сообщения в читаемом формате
-- @param total_members number Всего членов гильдии
-- @param without_notes number Количество без заметок
-- @param members table Список членов
local function ExportMessages(total_members, without_notes, members)
    AddMessage("\n|cFFFFFF00=== ЭКСПОРТ ДАННЫХ ===|r")
    AddMessage(string.format("Дата: %s", date("%d.%m.%Y %H:%M")))
    AddMessage(string.format("Всего: %d, Без заметок: %d", total_members, without_notes))
    AddMessage("\n|cFF00FFFFСписок для копирования:|r")
    
    for i, member in ipairs(members) do
        AddMessage(string.format("%d. %s | %d | %s | %s", 
            i, member.name, member.level, member.class, member.rank))
    end
end

--- Экспорт функций модуля
_G.GuildHelperChatLog = {
    AddMessage = AddMessage,
    ClearMessages = ClearMessages,
    GetMessages = GetMessages,
    GetMessagesText = GetMessagesText,
    ExportMessages = ExportMessages,
}

