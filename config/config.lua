--- Конфигурация аддона GuildHelper
-- @module config

local ADDON_NAME = "GuildHelper"

--- Константы аддона
local CONSTANTS = {
    VERSION = "1.1.0",
    MESSAGE_DELAY = 10, -- Задержка между сообщениями в секундах
}

--- Настройки по умолчанию
local DEFAULTS = {
    version = CONSTANTS.VERSION,
    onlineOnly = false,
    groupByRank = false,
    autoOpenChat = true,
    framePosition = {},
    chatPosition = {},
    notificationMessage = "Привет! Пожалуйста, заполни заметку в гильдии. Что бы аддон сработал напиши мне в ЛС: гз текст_заметки (например: гз Олег Демон 3.5к гс)",
}

--- Команды для установки заметок через шепот
local WHISPER_COMMANDS = {
    "^гз%s+(.+)",           -- гз текст
    "^заметка%s+(.+)",      -- заметка текст
    "^мзаметка%s+(.+)",     -- мзаметка текст
    "^note>%s*(.+)",        -- note> текст
    "^>>%s*(.+)",           -- >> текст
}

--- Экспорт конфигурации
_G.GuildHelperConfig = {
    ADDON_NAME = ADDON_NAME,
    CONSTANTS = CONSTANTS,
    DEFAULTS = DEFAULTS,
    WHISPER_COMMANDS = WHISPER_COMMANDS,
}

