--- Модуль обработки slash-команд
-- @module core.commands

local config = GuildHelperConfig
local VERSION = config.CONSTANTS.VERSION

-- Локализация глобальных функций
local string_match = string.match
local string_lower = string.lower
local string_len = string.len
local string_format = string.format

--- Показывает справку по командам
local function ShowHelp()
    print("|cFFFFFF00=== GuildHelper v" .. VERSION .. " ===|r")
    print("|cFF00FFFFДоступные команды:|r")
    print("|cFFFFFF00/gh|r или |cFFFFFF00/gh show|r - Открыть главное окно")
    print("|cFFFFFF00/gh check|r - Найти членов без заметок (в чат)")
    print("|cFFFFFF00/gh scan|r - То же, что и check")
    print("|cFFFFFF00/gh chat|r - Открыть окно журнала")
    print("|cFFFFFF00/gh online|r - Показать только онлайн")
    print("|cFFFFFF00/gh notify|r - Отправить уведомления всем без заметок")
    print("|cFFFFFF00/gh setmsg <текст>|r - Установить текст уведомления")
    print("|cFFFFFF00/gh minimap|r - Показать/скрыть кнопку миникарты")
    print("|cFFFFFF00/gh help|r - Показать эту справку")
    print(" ")
    print("|cFF00FFFFДля игроков (в ЛС офицеру):|r")
    print("|cFFFFFF00гз <текст>|r - Установить заметку (рекомендуется)")
    print("|cFFFFFF00заметка <текст>|r - Полная форма")
    print("|cFFFFFF00мзаметка <текст>|r - Моя заметка")
    print("|cFFFFFF00note> <текст>|r - English version")
    print("|cFFFFFF00>> <текст>|r - Короткий вариант")
    print(" ")
    print("|cFF808080Примеры:|r")
    print("|cFF808080  гз Танк, рейды по вечерам|r")
    print("|cFF808080  заметка ДД, онлайн днем|r")
    print("|cFF808080  >> Хил, выходные|r")
    print("|cFFFFFF00=====================================|r")
end

--- Выполняет сканирование и выводит результаты
-- @param show_in_chat boolean Вывести в чат
-- @param online_only boolean Только онлайн игроки
local function PerformScan(show_in_chat, online_only)
    local output_func = show_in_chat and GuildHelperChatLog.AddMessage or print
    
    local members, count, total = GuildHelperScanner.ScanMembersWithoutNotes(
        online_only or GuildHelperDB.onlineOnly,
        GuildHelperDB.groupByRank
    )
    
    if not members then
        local msg = "|cFFFFFF00[GuildHelper]|r Вы не состоите в гильдии или данные гильдии не загружены."
        output_func(msg)
        return
    end
    
    -- Сохранение результатов
    if GuildHelperUI then
        GuildHelperUI.SetResults(members, count, total)
    end
    
    -- Звуковое уведомление
    if count > 0 then
        PlaySound("MapPing")
    else
        PlaySound("igQuestComplete")
    end
    
    -- Вывод результатов
    output_func(" ")
    output_func("|cFFFFFF00===================================================================|r")
    output_func("|cFFFFFF00           GuildHelper: Члены без заметок                      |r")
    output_func("|cFFFFFF00===================================================================|r")
    output_func(" ")
    
    output_func(string_format("|cFF00FF00> Всего членов гильдии:|r |cFFFFFFFF%d|r", total))
    output_func(string_format("|cFFFF0000> Без заметок:|r |cFFFFFFFF%d|r |cFF808080(%.1f%%)|r", 
        count, (count / total) * 100))
    
    if online_only or GuildHelperDB.onlineOnly then
        output_func("|cFFFFAA00> Фильтр: Только онлайн игроки|r")
    end
    if GuildHelperDB.groupByRank then
        output_func("|cFFFFAA00> Группировка: По рангам|r")
    end
    
    output_func(" ")
    
    if count > 0 then
        -- Таблица с результатами
        local table_lines = GuildHelperFormatting.FormatMembersAsTable(members, GuildHelperDB.groupByRank)
        for _, line in ipairs(table_lines) do
            output_func(line)
        end
        
        output_func(" ")
        output_func(string_format("|cFF00AAFF===================================================================|r"))
        output_func(string_format("|cFF00AAFF  Итого найдено: %-3d игроков без заметок                        |r", count))
        output_func(string_format("|cFF00AAFF===================================================================|r"))
        
        output_func(" ")
        output_func("|cFF808080Легенда:|r |cFF00FF00*|r |cFF808080- В сети |r  |cFF808080o - Не в сети|r")
    else
        output_func("|cFF00FF00===================================================================|r")
        output_func("|cFF00FF00  [OK] У всех членов гильдии есть заметки!                        |r")
        output_func("|cFF00FF00===================================================================|r")
    end
    
    output_func(" ")
    
    -- Автоматическое открытие чата
    if show_in_chat and GuildHelperDB.autoOpenChat then
        if GuildHelperUI then
            GuildHelperUI.OpenChatWindow()
        end
    end
end

--- Обработчик slash команд
-- @param msg string Текст команды
local function SlashCommandHandler(msg)
    local command, args = string_match(msg, "^(%S+)%s*(.*)$")
    command = string_lower(command or msg or "")
    
    if command == "" or command == "show" or command == "ui" then
        if GuildHelperUI then
            GuildHelperUI.ToggleMainFrame()
        end
    elseif command == "help" then
        ShowHelp()
    elseif command == "check" or command == "scan" then
        PerformScan(false, false)
    elseif command == "chat" then
        if GuildHelperUI then
            GuildHelperUI.OpenChatWindow()
        end
    elseif command == "online" then
        PerformScan(false, true)
    elseif command == "notify" then
        local results = GuildHelperUI and GuildHelperUI.GetResults()
        if results and results.members then
            local message = GuildHelperDB.notificationMessage or config.DEFAULTS.notificationMessage
            GuildHelperNotifications.SendNotifications(results.members, message)
        else
            print("|cFFFF0000[GuildHelper]|r Сначала выполните сканирование!")
        end
    elseif command == "setmsg" then
        if args and string_len(args) > 0 then
            GuildHelperDB.notificationMessage = args
            print("|cFF00FF00[GuildHelper]|r Текст уведомления установлен:")
            print("|cFFFFFFFF" .. args .. "|r")
        else
            print("|cFFFF0000[GuildHelper]|r Использование: /gh setmsg <текст сообщения>")
            print("|cFFFFAA00Текущее сообщение:|r")
            print("|cFFFFFFFF" .. (GuildHelperDB.notificationMessage or config.DEFAULTS.notificationMessage) .. "|r")
        end
    elseif command == "minimap" then
        if GuildHelperMinimap then
            GuildHelperMinimap.Toggle()
        end
    else
        print("|cFFFF0000[GuildHelper]|r Неизвестная команда. Используйте /gh help для справки.")
    end
end

--- Регистрирует slash команды
local function RegisterSlashCommands()
    SLASH_GUILDHELPER1 = "/guildhelper"
    SLASH_GUILDHELPER2 = "/gh"
    SlashCmdList["GUILDHELPER"] = SlashCommandHandler
end

-- Автоматическая регистрация команд
RegisterSlashCommands()

--- Экспорт функций модуля
_G.GuildHelperCommands = {
    RegisterSlashCommands = RegisterSlashCommands,
    ShowHelp = ShowHelp,
    PerformScan = PerformScan,
}

