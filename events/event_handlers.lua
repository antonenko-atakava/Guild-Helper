--- Модуль обработки событий WoW
-- @module events.event_handlers

local config = GuildHelperConfig
local ADDON_NAME = config.ADDON_NAME
local VERSION = config.CONSTANTS.VERSION

-- Создание фрейма для обработки событий
local event_frame = CreateFrame("Frame")

--- Обработчик события ADDON_LOADED
-- @param addon_name string Имя загруженного аддона
local function OnAddonLoaded(addon_name)
    if addon_name ~= ADDON_NAME then
        return
    end
    
    -- Инициализация базы данных
    GuildHelperStorage.InitializeDatabase()
    
    print("|cFF00FF00[GuildHelper]|r версия " .. VERSION .. " загружен.")
    print("Используйте |cFFFFFF00/gh|r для открытия интерфейса или |cFFFFFF00/gh help|r для справки.")
    print("|cFFFFAA00[GuildHelper]|r Автоматическая обработка заметок включена.")
    
    -- Инициализация чата
    GuildHelperChatLog.AddMessage("|cFF00FF00Добро пожаловать в Guild Helper!|r")
    GuildHelperChatLog.AddMessage("Окно журнала готово к использованию.")
    GuildHelperChatLog.AddMessage("Используйте команду |cFFFFFF00/gh chat|r для открытия.")
end

--- Обработчик события GUILD_ROSTER_UPDATE
local function OnGuildRosterUpdate()
    -- Автоматическое обновление GUI при изменении ростера
    if GuildHelperFrame and GuildHelperFrame:IsVisible() then
        if GuildHelperUI then
            GuildHelperUI.UpdateGUI()
        end
    end
end

--- Обработчик события CHAT_MSG_WHISPER
-- @param message string Текст сообщения
-- @param sender string Отправитель
local function OnWhisperReceived(message, sender)
    GuildHelperWhisperHandler.HandleWhisper(message, sender)
end

--- Главный обработчик событий
-- @param self frame Фрейм события
-- @param event string Имя события
-- @param ... Параметры события
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon_name = ...
        OnAddonLoaded(addon_name)
    elseif event == "GUILD_ROSTER_UPDATE" then
        OnGuildRosterUpdate()
    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        OnWhisperReceived(message, sender)
    end
end

--- Регистрирует все необходимые события
local function RegisterEvents()
    event_frame:RegisterEvent("ADDON_LOADED")
    event_frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    event_frame:RegisterEvent("CHAT_MSG_WHISPER")
    event_frame:SetScript("OnEvent", OnEvent)
end

-- Автоматическая регистрация событий
RegisterEvents()

--- Экспорт функций модуля
_G.GuildHelperEvents = {
    RegisterEvents = RegisterEvents,
}

