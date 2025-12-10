--- Модуль обработки входящих шепотов
-- @module modules.whisper_handler

local config = GuildHelperConfig
local WHISPER_COMMANDS = config.WHISPER_COMMANDS

-- Локализация глобальных функций
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local GuildRosterSetPublicNote = GuildRosterSetPublicNote
local GuildRoster = GuildRoster
local SendChatMessage = SendChatMessage
local PlaySound = PlaySound
local string_match = string.match
local string_len = string.len
local string_format = string.format

--- Устанавливает заметку игроку в гильдии
-- @param player_name string Имя игрока
-- @param note_text string Текст заметки
-- @return boolean Успешность операции
local function SetGuildMemberNote(player_name, note_text)
    local num_members = GetNumGuildMembers()
    
    for i = 1, num_members do
        local name = GetGuildRosterInfo(i)
        if name == player_name then
            GuildRosterSetPublicNote(i, note_text)
            return true
        end
    end
    
    return false
end

--- Обрабатывает входящий шепот
-- @param message string Текст сообщения
-- @param sender string Отправитель
local function HandleWhisper(message, sender)
    local note_text = nil
    
    -- Проверка всех возможных форматов команд
    for _, pattern in ipairs(WHISPER_COMMANDS) do
        if string_match(message, pattern) then
            note_text = string_match(message, pattern)
            break
        end
    end
    
    if note_text and string_len(note_text) > 0 then
        -- Установка заметки
        if SetGuildMemberNote(sender, note_text) then
            SendChatMessage("Спасибо! Твоя заметка установлена: " .. note_text, "WHISPER", nil, sender)
            print(string_format("|cFF00FF00[GuildHelper]|r Заметка установлена для |cFFFFFF00%s|r: %s", sender, note_text))
            
            if GuildHelperChatLog then
                GuildHelperChatLog.AddMessage(string_format("✓ Заметка установлена: %s -> %s", sender, note_text))
            end
            
            -- Звуковое уведомление
            PlaySound("AuctionWindowClose")
            
            -- Обновление данных гильдии
            GuildRoster()
        else
            SendChatMessage("Ошибка: не могу найти тебя в гильдии.", "WHISPER", nil, sender)
            print(string_format("|cFFFF0000[GuildHelper]|r Игрок %s не найден в гильдии", sender))
            PlaySound("igQuestFailed")
        end
    end
end

--- Экспорт функций модуля
_G.GuildHelperWhisperHandler = {
    HandleWhisper = HandleWhisper,
}

