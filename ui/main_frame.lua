--- Модуль управления главным окном
-- @module ui.main_frame

local config = GuildHelperConfig
local VERSION = config.CONSTANTS.VERSION

-- Локализация глобальных функций
local _G = _G
local string_format = string.format
local tostring = tostring

-- Ссылки на результаты сканирования
local cached_results = {}

--- Инициализация главного окна
-- @param frame table Фрейм окна
local function InitializeMainFrame(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    
    -- Установка заголовков
    local title = _G["GuildHelperFrame_Title"]
    local subtitle = _G["GuildHelperFrame_Subtitle"]
    local version = _G["GuildHelperFrame_Version"]
    
    if title then
        title:SetText("Guild Helper")
    end
    if subtitle then
        subtitle:SetText("Управление заметками гильдии")
    end
    if version then
        version:SetText("v" .. VERSION)
    end
end

--- Обновляет GUI главного окна
local function UpdateGUI()
    if not GuildHelperFrame then
        return
    end
    
    -- Обновление счетчиков
    if cached_results.totalMembers then
        local total_members_text = _G["GuildHelperFrame_TotalMembers"]
        local without_notes_text = _G["GuildHelperFrame_WithoutNotes"]
        local progress_bar = _G["GuildHelperFrame_ProgressBar"]
        local progress_text = _G["GuildHelperFrame_ProgressBar_Text"]
        
        local percentage = (cached_results.withoutNotes / cached_results.totalMembers) * 100
        
        if total_members_text then
            total_members_text:SetText(tostring(cached_results.totalMembers))
        end
        if without_notes_text then
            without_notes_text:SetText(string_format("%d (%.1f%%)", cached_results.withoutNotes, percentage))
        end
        
        -- Обновление прогресс-бара
        if progress_bar then
            progress_bar:SetValue(percentage)
            -- Цвет в зависимости от процента
            if percentage < 10 then
                progress_bar:SetStatusBarColor(0.2, 0.8, 0.2) -- зеленый
            elseif percentage < 30 then
                progress_bar:SetStatusBarColor(0.8, 0.8, 0.2) -- желтый
            else
                progress_bar:SetStatusBarColor(0.8, 0.2, 0.2) -- красный
            end
        end
        
        if progress_text then
            progress_text:SetText(string_format("%.1f%% без заметок", percentage))
        end
        
        -- Обновление иконок
        local icon = _G["GuildHelperFrame_Icon"]
        local stats_icon = _G["GuildHelperFrame_StatsIcon"]
        local settings_icon = _G["GuildHelperFrame_SettingsIcon"]
        local results_icon = _G["GuildHelperFrame_ResultsIcon"]
        
        if icon then
            icon:SetTexture("Interface\\Icons\\Achievement_Guild_Doctorisin")
        end
        if stats_icon then
            stats_icon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_08")
        end
        if settings_icon then
            settings_icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_08")
        end
        if results_icon then
            results_icon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
        end
        
        -- Обновление текста результатов
        local text = _G["GuildHelperFrame_ScrollFrame_ScrollChild_Text"]
        
        if text then
            if cached_results.withoutNotes > 0 then
                local formatted_text = GuildHelperFormatting.FormatMembersCompact(cached_results.members)
                text:SetText(formatted_text)
            else
                text:SetText("|cFF00FF00[OK] Все члены имеют заметки!|r")
            end
        end
    else
        local total_members_text = _G["GuildHelperFrame_TotalMembers"]
        local without_notes_text = _G["GuildHelperFrame_WithoutNotes"]
        local progress_bar = _G["GuildHelperFrame_ProgressBar"]
        local progress_text = _G["GuildHelperFrame_ProgressBar_Text"]
        
        if total_members_text then
            total_members_text:SetText("|cFF808080Нет данных|r")
        end
        if without_notes_text then
            without_notes_text:SetText("|cFF808080Запустите сканирование...|r")
        end
        if progress_bar then
            progress_bar:SetValue(0)
        end
        if progress_text then
            progress_text:SetText("Ожидание...")
        end
    end
end

--- Обновляет статус уведомлений
local function UpdateNotificationStatus()
    local status_text = _G["GuildHelperFrame_NotifyStatus"]
    if not status_text then
        return
    end
    
    local queue_size = GuildHelperNotifications.GetQueueSize()
    if queue_size > 0 then
        local dots = string.rep(".", (GetTime() % 3) + 1)
        status_text:SetText(string_format("|cFFFFAA00Отправка%s В очереди: %d|r", dots, queue_size))
    elseif GuildHelperNotifications.IsProcessing() then
        status_text:SetText("|cFFFFAA00Отправка...|r")
    else
        status_text:SetText("")
    end
end

--- Очищает результаты сканирования
local function ClearResults()
    cached_results = {}
    UpdateGUI()
end

--- Сохраняет результаты сканирования
-- @param members table Список членов
-- @param without_notes number Количество без заметок
-- @param total_members number Всего членов
local function SetResults(members, without_notes, total_members)
    cached_results = {
        members = members,
        withoutNotes = without_notes,
        totalMembers = total_members,
    }
    UpdateGUI()
end

--- Получает сохраненные результаты
-- @return table Результаты сканирования
local function GetResults()
    return cached_results
end

--- Показывает/скрывает главное окно
local function ToggleMainFrame()
    if not GuildHelperFrame then
        return
    end
    
    if GuildHelperFrame:IsVisible() then
        if GuildHelperStorage then
            GuildHelperStorage.SaveFramePosition(GuildHelperFrame, "framePosition")
        end
        GuildHelperFrame:Hide()
    else
        -- Загрузка настроек в GUI
        local online_check = _G["GuildHelperFrame_OnlineOnlyCheckbox"]
        local group_check = _G["GuildHelperFrame_GroupByRankCheckbox"]
        
        if online_check then
            online_check:SetChecked(GuildHelperDB.onlineOnly)
        end
        if group_check then
            group_check:SetChecked(GuildHelperDB.groupByRank)
        end
        
        if GuildHelperStorage then
            GuildHelperStorage.LoadFramePosition(GuildHelperFrame, "framePosition")
        end
        GuildHelperFrame:Show()
        UpdateGUI()
    end
end

--- Экспорт функций модуля
_G.GuildHelperUI = {
    InitializeMainFrame = InitializeMainFrame,
    UpdateGUI = UpdateGUI,
    UpdateNotificationStatus = UpdateNotificationStatus,
    ClearResults = ClearResults,
    SetResults = SetResults,
    GetResults = GetResults,
    ToggleMainFrame = ToggleMainFrame,
}

