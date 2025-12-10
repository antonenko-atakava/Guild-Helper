-- GuildHelper.lua
-- Аддон для поиска членов гильдии без заметок

local ADDON_NAME = "GuildHelper"
local VERSION = "1.0.0"

-- Локальные переменные для оптимизации
local _G = _G
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local string_format = string.format
local string_match = string.match
local tinsert = table.insert
local tconcat = table.concat

-- Инициализация аддона
local GuildHelper = CreateFrame("Frame")
GuildHelper:RegisterEvent("ADDON_LOADED")
GuildHelper:RegisterEvent("GUILD_ROSTER_UPDATE")
GuildHelper:RegisterEvent("CHAT_MSG_WHISPER")

-- База данных по умолчанию
local defaults = {
    version = VERSION,
    onlineOnly = false,
    groupByRank = false,
    autoOpenChat = true,
    framePosition = {},
    chatPosition = {},
    notificationMessage = "Привет! Пожалуйста, заполни заметку в гильдии. Что бы аддон сработал напиши мне в ЛС: гз текст_заметки (например: гз Олег Демон 3.5к гс)",
}

-- Глобальные переменные для хранения данных
local cachedResults = {}
local chatMessages = {}
local messageQueue = {}
local isProcessingQueue = false
local lastMessageTime = 0
local MESSAGE_DELAY = 10 -- Задержка между сообщениями в секундах (защита от спама)

-- ============================================
-- СИСТЕМА УВЕДОМЛЕНИЙ И ОБРАБОТКИ ЗАМЕТОК
-- ============================================

-- Функция для отправки сообщения с задержкой
local function SendWhisperWithDelay(name, message)
    tinsert(messageQueue, {name = name, message = message})
    
    if not isProcessingQueue then
        isProcessingQueue = true
        GuildHelper:SetScript("OnUpdate", ProcessMessageQueue)
    end
end

-- Обработка очереди сообщений
function ProcessMessageQueue(self, elapsed)
    lastMessageTime = lastMessageTime + elapsed
    
    if lastMessageTime >= MESSAGE_DELAY and #messageQueue > 0 then
        local msg = table.remove(messageQueue, 1)
        SendChatMessage(msg.message, "WHISPER", nil, msg.name)
        
        local remaining = #messageQueue
        print(string_format("|cFF00FF00[GuildHelper]|r Отправлено сообщение игроку |cFFFFFF00%s|r |cFF808080(осталось: %d)|r", msg.name, remaining))
        AddChatMessage(string_format("-> %s (осталось: %d)", msg.name, remaining))
        
        lastMessageTime = 0
        
        -- Обновление UI
        UpdateNotificationStatus()
    end
    
    if #messageQueue == 0 then
        isProcessingQueue = false
        self:SetScript("OnUpdate", nil)
        print("|cFF00FF00[GuildHelper]|r Все уведомления отправлены!")
        AddChatMessage("=== Отправка завершена ===")
        PlaySound("LevelUp")
        UpdateNotificationStatus()
    end
end

-- Функция для отправки уведомлений всем без заметок
function SendNotificationsToMembers()
    if not cachedResults.members or cachedResults.withoutNotes == 0 then
        print("|cFFFF0000[GuildHelper]|r Сначала выполните сканирование!")
        return
    end
    
    local onlineCount = 0
    local message = GuildHelperDB.notificationMessage or defaults.notificationMessage
    
    -- Подсчет онлайн игроков
    for i, member in ipairs(cachedResults.members) do
        if member.isOnline then
            onlineCount = onlineCount + 1
        end
    end
    
    if onlineCount == 0 then
        print("|cFFFFAA00[GuildHelper]|r Нет игроков онлайн без заметок.")
        return
    end
    
    -- Подтверждение отправки
    print(string_format("|cFFFFFF00[GuildHelper]|r Будет отправлено %d уведомлений. Время: ~%d сек.", onlineCount, onlineCount * MESSAGE_DELAY))
    print("|cFF00FF00[GuildHelper]|r Начинаю отправку...")
    PlaySound("igMainMenuOpen")
    
    -- Добавление в очередь
    for i, member in ipairs(cachedResults.members) do
        if member.isOnline then
            SendWhisperWithDelay(member.name, message)
        end
    end
    
    AddChatMessage(string_format("=== Отправка уведомлений: %d игроков ===", onlineCount))
    AddChatMessage(string_format("Время ожидания: ~%d секунд", onlineCount * MESSAGE_DELAY))
    
    -- Обновление UI
    UpdateNotificationStatus()
end

-- Обновление статуса уведомлений в UI
function UpdateNotificationStatus()
    local statusText = _G["GuildHelperFrame_NotifyStatus"]
    if statusText then
        local queueSize = #messageQueue
        if queueSize > 0 then
            local dots = string.rep(".", (GetTime() % 3) + 1)
            statusText:SetText(string_format("|cFFFFAA00Отправка%s В очереди: %d|r", dots, queueSize))
        elseif isProcessingQueue then
            statusText:SetText("|cFFFFAA00Отправка...|r")
        else
            statusText:SetText("")
        end
    end
end

-- Функция для установки заметки игроку
local function SetGuildMemberNote(playerName, noteText)
    -- Поиск индекса игрока в гильдии
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name = GetGuildRosterInfo(i)
        if name == playerName then
            GuildRosterSetPublicNote(i, noteText)
            return true
        end
    end
    return false
end

-- Обработка входящих шепотов
local function HandleWhisper(message, sender)
    -- Проверка на различные форматы команды
    -- Поддерживаемые форматы: гз, заметка, note>, >>
    local noteText = nil
    
    -- Проверка всех возможных форматов
    if string.match(message, "^гз%s+(.+)") then
        noteText = string.match(message, "^гз%s+(.+)")
    elseif string.match(message, "^заметка%s+(.+)") then
        noteText = string.match(message, "^заметка%s+(.+)")
    elseif string.match(message, "^мзаметка%s+(.+)") then
        noteText = string.match(message, "^мзаметка%s+(.+)")
    elseif string.match(message, "^note>%s*(.+)") then
        noteText = string.match(message, "^note>%s*(.+)")
    elseif string.match(message, "^>>%s*(.+)") then
        noteText = string.match(message, "^>>%s*(.+)")
    end
    
    if noteText and string.len(noteText) > 0 then
        -- Установка заметки
        if SetGuildMemberNote(sender, noteText) then
            SendChatMessage("Спасибо! Твоя заметка установлена: " .. noteText, "WHISPER", nil, sender)
            print(string_format("|cFF00FF00[GuildHelper]|r Заметка установлена для |cFFFFFF00%s|r: %s", sender, noteText))
            AddChatMessage(string_format("✓ Заметка установлена: %s -> %s", sender, noteText))
            
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

-- ============================================
-- СИСТЕМА ЧАТА
-- ============================================

-- Добавление сообщения в чат аддона
function AddChatMessage(msg)
    tinsert(chatMessages, msg)
    
    -- Обновление окна чата, если оно открыто
    if GuildHelperChatFrame and GuildHelperChatFrame:IsVisible() then
        UpdateChatWindow()
    end
end

-- Очистка чата аддона
function ClearChatMessages()
    chatMessages = {}
    if GuildHelperChatFrame and GuildHelperChatFrame:IsVisible() then
        UpdateChatWindow()
    end
end

-- Обновление окна чата
function UpdateChatWindow()
    if not GuildHelperChatFrame then return end
    
    local scrollFrame = _G["GuildHelperChatFrame_ScrollFrame"]
    if not scrollFrame then return end
    
    local scrollChild = _G["GuildHelperChatFrame_ScrollFrame_ScrollChild"]
    if not scrollChild then return end
    
    local text = _G["GuildHelperChatFrame_ScrollFrame_ScrollChild_Text"]
    if not text then return end
    
    if #chatMessages == 0 then
        text:SetText("|cFF808080Нет сообщений...|r")
    else
        text:SetText(tconcat(chatMessages, "\n"))
    end
    
    -- Прокрутка вниз
    scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
end

-- Открытие окна чата
function OpenChatWindow()
    if not GuildHelperChatFrame then return end
    LoadFramePosition(GuildHelperChatFrame, "chatPosition")
    GuildHelperChatFrame:Show()
    UpdateChatWindow()
end

-- Закрытие окна чата (с сохранением позиции)
local function CloseChat()
    if not GuildHelperChatFrame then return end
    SaveFramePosition(GuildHelperChatFrame, "chatPosition")
    GuildHelperChatFrame:Hide()
end

-- ============================================
-- ФУНКЦИИ ФОРМАТИРОВАНИЯ
-- ============================================

-- Функция для создания разделителя таблицы
local function CreateTableDivider()
    return "+--------------------+------+-------------+----------------------+"
end

-- Функция для создания заголовка таблицы
local function CreateTableHeader()
    local header = "+--------------------+------+-------------+----------------------+"
    local titles = "| Имя                | Ур.  | Класс       | Ранг                 |"
    local divider = "+--------------------+------+-------------+----------------------+"
    return header .. "\n" .. titles .. "\n" .. divider
end

-- Функция для создания строки таблицы
local function CreateTableRow(name, level, class, rank, isOnline)
    -- Обрезка длинных имен
    if string.len(name) > 18 then
        name = string.sub(name, 1, 15) .. "..."
    end
    if string.len(rank) > 20 then
        rank = string.sub(rank, 1, 17) .. "..."
    end
    if string.len(class) > 11 then
        class = string.sub(class, 1, 8) .. "..."
    end
    
    -- Форматирование с выравниванием
    local statusSymbol = isOnline and "*" or "o"
    local nameCol = string.format(" %s %-17s", statusSymbol, name)
    local levelCol = string.format(" %-4d", level)
    local classCol = string.format(" %-11s", class)
    local rankCol = string.format(" %-20s", rank)
    
    return "|" .. nameCol .. "|" .. levelCol .. "|" .. classCol .. "|" .. rankCol .. "|"
end

-- Функция для создания футера таблицы
local function CreateTableFooter()
    return "+--------------------+------+-------------+----------------------+"
end

-- Функция для форматирования вывода в виде таблицы
local function FormatMembersAsTable(members, groupByRank)
    local lines = {}
    
    -- Заголовок таблицы
    tinsert(lines, "|cFF00AAFF" .. CreateTableHeader() .. "|r")
    
    if groupByRank then
        -- Группировка по рангам
        local currentRank = nil
        for i, member in ipairs(members) do
            if member.rank ~= currentRank then
                if currentRank ~= nil then
                    -- Разделитель между группами
                    tinsert(lines, "|cFF888888+--------------------+------+-------------+----------------------+|r")
                end
                currentRank = member.rank
            end
            
            -- Цвет класса
            local classColor = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
            local colorStr = string_format("|cFF%02x%02x%02x", 
                classColor.r * 255, 
                classColor.g * 255, 
                classColor.b * 255)
            
            local statusColor = member.isOnline and "|cFF00FF00" or "|cFF808080"
            local row = CreateTableRow(member.name, member.level, member.class, member.rank, member.isOnline)
            tinsert(lines, statusColor .. row .. "|r")
        end
    else
        -- Обычный список
        for i, member in ipairs(members) do
            local classColor = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
            local colorStr = string_format("|cFF%02x%02x%02x", 
                classColor.r * 255, 
                classColor.g * 255, 
                classColor.b * 255)
            
            local statusColor = member.isOnline and "|cFF00FF00" or "|cFF808080"
            local row = CreateTableRow(member.name, member.level, member.class, member.rank, member.isOnline)
            tinsert(lines, statusColor .. row .. "|r")
        end
    end
    
    -- Футер таблицы
    tinsert(lines, "|cFF00AAFF" .. CreateTableFooter() .. "|r")
    
    return lines
end

-- ============================================
-- ОСНОВНЫЕ ФУНКЦИИ СКАНИРОВАНИЯ
-- ============================================

-- Функция поиска членов без заметок
function FindMembersWithoutNotes(showInChat, onlineOnly, groupByRank)
    -- Запрос данных гильдии
    GuildRoster()
    
    local totalMembers = GetNumGuildMembers()
    if totalMembers == 0 then
        local msg = "|cFFFFFF00[GuildHelper]|r Вы не состоите в гильдии или данные гильдии не загружены."
        print(msg)
        if showInChat then
            AddChatMessage(msg)
        end
        return
    end
    
    local membersWithoutNotes = {}
    local count = 0
    
    -- Настройки фильтрации
    onlineOnly = onlineOnly or GuildHelperDB.onlineOnly
    groupByRank = groupByRank or GuildHelperDB.groupByRank
    
    -- Проход по всем членам гильдии
    for i = 1, totalMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline = GetGuildRosterInfo(i)
        
        -- Проверка на отсутствие или пустую заметку
        if not note or string_match(note, "^%s*$") then
            -- Фильтр по онлайн статусу
            if not onlineOnly or isOnline then
                count = count + 1
                
                -- Сохранение информации о члене
                local memberInfo = {
                    name = name or "Неизвестно",
                    level = level or 0,
                    class = class or "Неизвестно",
                    rank = rank or "Неизвестно",
                    rankIndex = rankIndex or 10,
                    isOnline = isOnline
                }
                
                membersWithoutNotes[count] = memberInfo
            end
        end
    end
    
    -- Сортировка по рангу, если нужно
    if groupByRank then
        table.sort(membersWithoutNotes, function(a, b)
            if a.rankIndex == b.rankIndex then
                return a.name < b.name
            end
            return a.rankIndex < b.rankIndex
        end)
    end
    
    -- Сохранение результатов
    cachedResults = {
        totalMembers = totalMembers,
        withoutNotes = count,
        members = membersWithoutNotes
    }
    
    -- Вывод результатов
    local outputFunc = showInChat and AddChatMessage or print
    
    -- Звуковое уведомление
    if count > 0 then
        PlaySound("MapPing")
    else
        PlaySound("igQuestComplete")
    end
    
    -- Заголовок отчета
    outputFunc(" ")
    outputFunc("|cFFFFFF00===================================================================|r")
    outputFunc("|cFFFFFF00           GuildHelper: Члены без заметок                      |r")
    outputFunc("|cFFFFFF00===================================================================|r")
    outputFunc(" ")
    
    -- Статистика
    outputFunc(string_format("|cFF00FF00> Всего членов гильдии:|r |cFFFFFFFF%d|r", totalMembers))
    outputFunc(string_format("|cFFFF0000> Без заметок:|r |cFFFFFFFF%d|r |cFF808080(%.1f%%)|r", 
        count, (count / totalMembers) * 100))
    
    if onlineOnly then
        outputFunc("|cFFFFAA00> Фильтр: Только онлайн игроки|r")
    end
    if groupByRank then
        outputFunc("|cFFFFAA00> Группировка: По рангам|r")
    end
    
    outputFunc(" ")
    
    if count > 0 then
        -- Таблица с результатами
        local tableLines = FormatMembersAsTable(membersWithoutNotes, groupByRank)
        for _, line in ipairs(tableLines) do
            outputFunc(line)
        end
        
        outputFunc(" ")
        outputFunc(string_format("|cFF00AAFF===================================================================|r"))
        outputFunc(string_format("|cFF00AAFF  Итого найдено: %-3d игроков без заметок                        |r", count))
        outputFunc(string_format("|cFF00AAFF===================================================================|r"))
        
        -- Легенда
        outputFunc(" ")
        outputFunc("|cFF808080Легенда:|r |cFF00FF00*|r |cFF808080- В сети |r  |cFF808080o - Не в сети|r")
    else
        outputFunc("|cFF00FF00===================================================================|r")
        outputFunc("|cFF00FF00  [OK] У всех членов гильдии есть заметки!                        |r")
        outputFunc("|cFF00FF00===================================================================|r")
    end
    
    outputFunc(" ")
    
    -- Обновление GUI если открыто
    if GuildHelperFrame and GuildHelperFrame:IsVisible() then
        UpdateGUI()
    end
    
    -- Автоматическое открытие чата
    if showInChat and GuildHelperDB.autoOpenChat then
        OpenChatWindow()
    end
    
    return count, totalMembers
end

-- ============================================
-- ФУНКЦИИ GUI
-- ============================================

-- Инициализация главного окна
function GuildHelper_OnLoad(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    
    -- Установка заголовков (современный дизайн)
    local title = _G["GuildHelperFrame_Title"]
    local subtitle = _G["GuildHelperFrame_Subtitle"]
    local version = _G["GuildHelperFrame_Version"]
    
    if title then title:SetText("Guild Helper") end
    if subtitle then subtitle:SetText("Управление заметками гильдии") end
    if version then version:SetText("v" .. VERSION) end
    
    -- Подсказки для кнопок
    local scanBtn = _G["GuildHelperFrame_ScanButton"]
    local showInChatBtn = _G["GuildHelperFrame_ShowInChatButton"]
    local openChatBtn = _G["GuildHelperFrame_OpenChatButton"]
    local refreshBtn = _G["GuildHelperFrame_RefreshButton"]
    local notifyBtn = _G["GuildHelperFrame_NotifyButton"]
    
    if scanBtn then
        scanBtn.tooltipText = "Сканировать гильдию и показать результаты"
    end
    if showInChatBtn then
        showInChatBtn.tooltipText = "Вывести результаты в журнал"
    end
    if openChatBtn then
        openChatBtn.tooltipText = "Открыть окно журнала"
    end
    if refreshBtn then
        refreshBtn.tooltipText = "Обновить данные гильдии"
    end
    if notifyBtn then
        notifyBtn.tooltipText = "Отправить уведомления всем без заметок"
    end
    
    -- Настройка области перетаскивания
    local dragArea = _G["GuildHelperFrame_DragArea"]
    if dragArea then
        dragArea:EnableMouse(true)
        dragArea:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Перетащите для перемещения окна", 1, 1, 1)
            GameTooltip:Show()
        end)
        dragArea:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Получение ссылок на кнопки (текст задан в XML)
    local scanBtn = _G["GuildHelperFrame_ScanButton"]
    local showInChatBtn = _G["GuildHelperFrame_ShowInChatButton"]
    local openChatBtn = _G["GuildHelperFrame_OpenChatButton"]
    local clearBtn = _G["GuildHelperFrame_ClearButton"]
    local closeBtn = _G["GuildHelperFrame_CloseButton"]
    
    -- Чекбоксы (текст задан в XML)
    local onlineCheck = _G["GuildHelperFrame_OnlineOnlyCheck"]
    local groupCheck = _G["GuildHelperFrame_GroupByRankCheck"]
    
    -- Обработчики кнопок
    if closeBtn then
        closeBtn:SetScript("OnClick", function()
            SaveFramePosition(GuildHelperFrame, "framePosition")
            GuildHelperFrame:Hide()
        end)
    end
    
    if scanBtn then
        scanBtn:SetScript("OnClick", function()
            FindMembersWithoutNotes(false)
        end)
    end
    
    if showInChatBtn then
        showInChatBtn:SetScript("OnClick", function()
            ClearChatMessages()
            FindMembersWithoutNotes(true)
        end)
    end
    
    if openChatBtn then
        openChatBtn:SetScript("OnClick", function()
            OpenChatWindow()
        end)
    end
    
    if clearBtn then
        clearBtn:SetScript("OnClick", function()
            ClearResults()
        end)
    end
    
    -- Обработчики чекбоксов
    if onlineCheck then
        onlineCheck:SetScript("OnClick", function(self)
            GuildHelperDB.onlineOnly = self:GetChecked()
        end)
    end
    
    if groupCheck then
        groupCheck:SetScript("OnClick", function(self)
            GuildHelperDB.groupByRank = self:GetChecked()
        end)
    end
end

-- Инициализация окна чата
function GuildHelperChat_OnLoad(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    
    local title = _G["GuildHelperChatFrame_Title"]
    if title then title:SetText("Guild Helper - Журнал") end
    
    -- Настройка области перетаскивания
    local dragArea = _G["GuildHelperChatFrame_DragArea"]
    if dragArea then
        dragArea:EnableMouse(true)
        dragArea:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Перетащите для перемещения окна", 1, 1, 1)
            GameTooltip:Show()
        end)
        dragArea:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Получение ссылок на кнопки (текст задан в XML)
    local clearBtn = _G["GuildHelperChatFrame_ClearButton"]
    local copyBtn = _G["GuildHelperChatFrame_CopyButton"]
    local exportBtn = _G["GuildHelperChatFrame_ExportButton"]
    local closeBtn = _G["GuildHelperChatFrame_CloseButton"]
    
    -- Обработчики кнопок
    if closeBtn then
        closeBtn:SetScript("OnClick", function()
            SaveFramePosition(GuildHelperChatFrame, "chatPosition")
            GuildHelperChatFrame:Hide()
        end)
    end
    
    if clearBtn then
        clearBtn:SetScript("OnClick", function()
            ClearChatMessages()
        end)
    end
    
    if copyBtn then
        copyBtn:SetScript("OnClick", function()
            CopyChatToClipboard()
        end)
    end
    
    if exportBtn then
        exportBtn:SetScript("OnClick", function()
            ExportResults()
        end)
    end
end

-- Обновление GUI
function UpdateGUI()
    if not GuildHelperFrame then return end
    
    -- Обновление счетчиков
    if cachedResults.totalMembers then
        local totalMembersText = _G["GuildHelperFrame_TotalMembers"]
        local withoutNotesText = _G["GuildHelperFrame_WithoutNotes"]
        local progressBar = _G["GuildHelperFrame_ProgressBar"]
        local progressText = _G["GuildHelperFrame_ProgressBar_Text"]
        
        local percentage = (cachedResults.withoutNotes / cachedResults.totalMembers) * 100
        
        if totalMembersText then
            totalMembersText:SetText(tostring(cachedResults.totalMembers))
        end
        if withoutNotesText then
            withoutNotesText:SetText(string_format("%d (%.1f%%)", cachedResults.withoutNotes, percentage))
        end
        
        -- Обновление прогресс-бара
        if progressBar then
            progressBar:SetValue(percentage)
            -- Цвет в зависимости от процента
            if percentage < 10 then
                progressBar:SetStatusBarColor(0.2, 0.8, 0.2) -- зеленый
            elseif percentage < 30 then
                progressBar:SetStatusBarColor(0.8, 0.8, 0.2) -- желтый
            else
                progressBar:SetStatusBarColor(0.8, 0.2, 0.2) -- красный
            end
        end
        
        if progressText then
            progressText:SetText(string_format("%.1f%% без заметок", percentage))
        end
        
        -- Обновление иконок (современный дизайн)
        local icon = _G["GuildHelperFrame_Icon"]
        local statsIcon = _G["GuildHelperFrame_StatsIcon"]
        local settingsIcon = _G["GuildHelperFrame_SettingsIcon"]
        local resultsIcon = _G["GuildHelperFrame_ResultsIcon"]
        
        if icon then
            icon:SetTexture("Interface\\Icons\\Achievement_Guild_Doctorisin")
        end
        if statsIcon then
            statsIcon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_08")
        end
        if settingsIcon then
            settingsIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_08")
        end
        if resultsIcon then
            resultsIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
        end
        
        -- Обновление текста в скролле - теперь в виде таблицы
        local text = _G["GuildHelperFrame_ScrollFrame_ScrollChild_Text"]
        
        if text then
            if cachedResults.withoutNotes > 0 then
                local lines = {}
                
                -- Заголовок таблицы для GUI
                tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
                tinsert(lines, "|cFF00AAFF| Имя        | Ур | Класс     | Ранг     ||r")
                tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
                
                for i, member in ipairs(cachedResults.members) do
                    local status = member.isOnline and "*" or "o"
                    local name = member.name
                    if string.len(name) > 10 then
                        name = string.sub(name, 1, 8) .. ".."
                    end
                    
                    local class = member.class
                    if string.len(class) > 9 then
                        class = string.sub(class, 1, 7) .. ".."
                    end
                    
                    local rank = member.rank
                    if string.len(rank) > 8 then
                        rank = string.sub(rank, 1, 6) .. ".."
                    end
                    
                    -- Цвет класса
                    local classColor = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
                    local colorStr = string_format("|cFF%02x%02x%02x", 
                        classColor.r * 255, 
                        classColor.g * 255, 
                        classColor.b * 255)
                    
                    local statusColor = member.isOnline and "|cFF00FF00" or "|cFF808080"
                    
                    tinsert(lines, string_format("|cFFFFFFFF| %s%s|r %-10s| %2d | %s%-9s|r | %-8s ||r", 
                        statusColor, status, name, member.level, colorStr, class, rank))
                end
                
                tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
                
                text:SetText(tconcat(lines, "\n"))
            else
                text:SetText("|cFF00FF00[OK] Все члены имеют заметки!|r")
            end
        end
    else
        local totalMembersText = _G["GuildHelperFrame_TotalMembers"]
        local withoutNotesText = _G["GuildHelperFrame_WithoutNotes"]
        local progressBar = _G["GuildHelperFrame_ProgressBar"]
        local progressText = _G["GuildHelperFrame_ProgressBar_Text"]
        
        if totalMembersText then
            totalMembersText:SetText("|cFF808080Нет данных|r")
        end
        if withoutNotesText then
            withoutNotesText:SetText("|cFF808080Запустите сканирование...|r")
        end
        if progressBar then
            progressBar:SetValue(0)
        end
        if progressText then
            progressText:SetText("Ожидание...")
        end
    end
end

-- Очистка результатов
function ClearResults()
    cachedResults = {}
    UpdateGUI()
end

-- Копирование в буфер (симуляция)
function CopyChatToClipboard()
    print("|cFFFFFF00[GuildHelper]|r Результаты готовы к копированию. Выделите текст в окне чата.")
end

-- Экспорт результатов
function ExportResults()
    if cachedResults.withoutNotes and cachedResults.withoutNotes > 0 then
        AddChatMessage("\n|cFFFFFF00=== ЭКСПОРТ ДАННЫХ ===|r")
        AddChatMessage(string_format("Дата: %s", date("%d.%m.%Y %H:%M")))
        AddChatMessage(string_format("Всего: %d, Без заметок: %d", 
            cachedResults.totalMembers, cachedResults.withoutNotes))
        AddChatMessage("\n|cFF00FFFFСписок для копирования:|r")
        
        for i, member in ipairs(cachedResults.members) do
            AddChatMessage(string_format("%d. %s | %d | %s | %s", 
                i, member.name, member.level, member.class, member.rank))
        end
        
        UpdateChatWindow()
        print("|cFF00FF00[GuildHelper]|r Данные экспортированы в окно чата.")
    else
        print("|cFFFF0000[GuildHelper]|r Нет данных для экспорта. Запустите сканирование.")
    end
end

-- Сохранение позиции окна
function SaveFramePosition(frame, positionKey)
    if not frame or not GuildHelperDB then return end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    GuildHelperDB[positionKey] = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
    }
end

-- Загрузка позиции окна
function LoadFramePosition(frame, positionKey)
    if not frame or not GuildHelperDB or not GuildHelperDB[positionKey] then return end
    
    local pos = GuildHelperDB[positionKey]
    if pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
    end
end

-- Показать/скрыть GUI
local function ToggleGUI()
    if not GuildHelperFrame then return end
    
    if GuildHelperFrame:IsVisible() then
        SaveFramePosition(GuildHelperFrame, "framePosition")
        GuildHelperFrame:Hide()
    else
        -- Загрузка настроек в GUI
        local onlineCheck = _G["GuildHelperFrame_OnlineOnlyCheck"]
        local groupCheck = _G["GuildHelperFrame_GroupByRankCheck"]
        
        if onlineCheck then onlineCheck:SetChecked(GuildHelperDB.onlineOnly) end
        if groupCheck then groupCheck:SetChecked(GuildHelperDB.groupByRank) end
        
        LoadFramePosition(GuildHelperFrame, "framePosition")
        GuildHelperFrame:Show()
        UpdateGUI()
    end
end

-- ============================================
-- КОМАНДЫ И ПОМОЩЬ
-- ============================================

-- Функция для показа помощи
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

-- Обработчик slash команд
local function SlashCommandHandler(msg)
    local command, args = string.match(msg, "^(%S+)%s*(.*)$")
    command = string.lower(command or msg or "")
    
    if command == "" or command == "show" or command == "ui" then
        ToggleGUI()
    elseif command == "help" then
        ShowHelp()
    elseif command == "check" or command == "scan" then
        FindMembersWithoutNotes(false)
    elseif command == "chat" then
        OpenChatWindow()
    elseif command == "online" then
        FindMembersWithoutNotes(false, true)
    elseif command == "notify" then
        SendNotificationsToMembers()
    elseif command == "setmsg" then
        if args and string.len(args) > 0 then
            GuildHelperDB.notificationMessage = args
            print("|cFF00FF00[GuildHelper]|r Текст уведомления установлен:")
            print("|cFFFFFFFF" .. args .. "|r")
        else
            print("|cFFFF0000[GuildHelper]|r Использование: /gh setmsg <текст сообщения>")
            print("|cFFFFAA00Текущее сообщение:|r")
            print("|cFFFFFFFF" .. (GuildHelperDB.notificationMessage or defaults.notificationMessage) .. "|r")
        end
    elseif command == "minimap" then
        GuildHelper_ToggleMinimapButton()
    else
        print("|cFFFF0000[GuildHelper]|r Неизвестная команда. Используйте /gh help для справки.")
    end
end

-- Регистрация slash команд
SLASH_GUILDHELPER1 = "/guildhelper"
SLASH_GUILDHELPER2 = "/gh"
SlashCmdList["GUILDHELPER"] = SlashCommandHandler

-- ============================================
-- ОБРАБОТЧИКИ СОБЫТИЙ
-- ============================================

-- Обработчик событий
GuildHelper:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            -- Инициализация базы данных
            if not GuildHelperDB then
                GuildHelperDB = {}
            end
            
            -- Слияние с настройками по умолчанию
            for k, v in pairs(defaults) do
                if GuildHelperDB[k] == nil then
                    GuildHelperDB[k] = v
                end
            end
            
            print("|cFF00FF00[GuildHelper]|r версия " .. VERSION .. " загружен.")
            print("Используйте |cFFFFFF00/gh|r для открытия интерфейса или |cFFFFFF00/gh help|r для справки.")
            print("|cFFFFAA00[GuildHelper]|r Автоматическая обработка заметок включена.")
            
            -- Автоматическое создание окна чата
            AddChatMessage("|cFF00FF00Добро пожаловать в Guild Helper!|r")
            AddChatMessage("Окно журнала готово к использованию.")
            AddChatMessage("Используйте команду |cFFFFFF00/gh chat|r для открытия.")
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- Автоматическое обновление GUI при изменении ростера
        if GuildHelperFrame and GuildHelperFrame:IsVisible() then
            UpdateGUI()
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local message, sender = ...
        HandleWhisper(message, sender)
    end
end)


