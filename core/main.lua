--- Главный файл инициализации аддона GuildHelper
-- @module core.main

local config = GuildHelperConfig
local ADDON_NAME = config.ADDON_NAME
local VERSION = config.CONSTANTS.VERSION

--- Глобальные обработчики для XML
-- Эти функции должны быть глобальными для вызова из XML

--- Инициализация главного окна (вызывается из XML)
-- @param frame table Фрейм главного окна
function GuildHelper_OnLoad(frame)
    if GuildHelperUI then
        GuildHelperUI.InitializeMainFrame(frame)
    end
    
    -- Настройка области перетаскивания
    local drag_area = _G["GuildHelperFrame_DragArea"]
    if drag_area then
        drag_area:EnableMouse(true)
        drag_area:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Перетащите для перемещения окна", 1, 1, 1)
            GameTooltip:Show()
        end)
        drag_area:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Обработчики кнопок
    local scan_btn = _G["GuildHelperFrame_ScanButton"]
    local show_in_chat_btn = _G["GuildHelperFrame_ShowInChatButton"]
    local open_chat_btn = _G["GuildHelperFrame_OpenChatButton"]
    local clear_btn = _G["GuildHelperFrame_ClearButton"]
    local close_btn = _G["GuildHelperFrame_CloseButton"]
    local notify_btn = _G["GuildHelperFrame_NotifyButton"]
    local refresh_btn = _G["GuildHelperFrame_RefreshButton"]
    
    if close_btn then
        close_btn:SetScript("OnClick", function()
            if GuildHelperStorage then
                GuildHelperStorage.SaveFramePosition(GuildHelperFrame, "framePosition")
            end
            GuildHelperFrame:Hide()
        end)
    end
    
    if scan_btn then
        scan_btn:SetScript("OnClick", function()
            if GuildHelperCommands then
                GuildHelperCommands.PerformScan(false, false)
            end
        end)
    end
    
    if show_in_chat_btn then
        show_in_chat_btn:SetScript("OnClick", function()
            GuildHelperChatLog.ClearMessages()
            if GuildHelperCommands then
                GuildHelperCommands.PerformScan(true, false)
            end
        end)
    end
    
    if open_chat_btn then
        open_chat_btn:SetScript("OnClick", function()
            if GuildHelperUI then
                GuildHelperUI.OpenChatWindow()
            end
        end)
    end
    
    if clear_btn then
        clear_btn:SetScript("OnClick", function()
            if GuildHelperUI then
                GuildHelperUI.ClearResults()
            end
        end)
    end
    
    if notify_btn then
        notify_btn:SetScript("OnClick", function()
            local results = GuildHelperUI and GuildHelperUI.GetResults()
            if results and results.members then
                local message = GuildHelperDB.notificationMessage or config.DEFAULTS.notificationMessage
                GuildHelperNotifications.SendNotifications(results.members, message)
            else
                print("|cFFFF0000[GuildHelper]|r Сначала выполните сканирование!")
            end
        end)
    end
    
    if refresh_btn then
        refresh_btn:SetScript("OnClick", function()
            GuildRoster()
            print("|cFF00FF00[GuildHelper]|r Данные гильдии обновлены!")
        end)
    end
    
    -- Обработчики чекбоксов
    local online_check = _G["GuildHelperFrame_OnlineOnlyCheckbox"]
    local group_check = _G["GuildHelperFrame_GroupByRankCheckbox"]
    
    if online_check then
        online_check:SetScript("OnClick", function(self)
            GuildHelperDB.onlineOnly = self:GetChecked()
        end)
    end
    
    if group_check then
        group_check:SetScript("OnClick", function(self)
            GuildHelperDB.groupByRank = self:GetChecked()
        end)
    end
end

--- Инициализация окна чата (вызывается из XML)
-- @param frame table Фрейм окна чата
function GuildHelperChat_OnLoad(frame)
    if GuildHelperUI then
        GuildHelperUI.InitializeChatWindow(frame)
    end
    
    -- Настройка области перетаскивания
    local drag_area = _G["GuildHelperChatFrame_DragArea"]
    if drag_area then
        drag_area:EnableMouse(true)
        drag_area:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Перетащите для перемещения окна", 1, 1, 1)
            GameTooltip:Show()
        end)
        drag_area:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Обработчики кнопок
    local close_btn = _G["GuildHelperChatFrame_CloseButton"]
    
    if close_btn then
        close_btn:SetScript("OnClick", function()
            if GuildHelperStorage then
                GuildHelperStorage.SaveFramePosition(GuildHelperChatFrame, "chatPosition")
            end
            GuildHelperChatFrame:Hide()
        end)
    end
end

--- Глобальные обработчики для удобного доступа
_G.GuildHelper_OnLoad = GuildHelper_OnLoad
_G.GuildHelperChat_OnLoad = GuildHelperChat_OnLoad

--- Сохранение позиции главного окна
function SaveFramePosition(frame, position_key)
    if GuildHelperStorage then
        GuildHelperStorage.SaveFramePosition(frame, position_key)
    end
end

--- Загрузка позиции главного окна
function LoadFramePosition(frame, position_key)
    if GuildHelperStorage then
        GuildHelperStorage.LoadFramePosition(frame, position_key)
    end
end

--- Обновление GUI
function UpdateGUI()
    if GuildHelperUI then
        GuildHelperUI.UpdateGUI()
    end
end

--- Обновление окна чата
function UpdateChatWindow()
    if GuildHelperUI then
        GuildHelperUI.UpdateChatWindow()
    end
end

--- Очистка результатов
function ClearResults()
    if GuildHelperUI then
        GuildHelperUI.ClearResults()
    end
end

--- Экспорт глобальных функций для обратной совместимости с XML
_G.SaveFramePosition = SaveFramePosition
_G.LoadFramePosition = LoadFramePosition
_G.UpdateGUI = UpdateGUI
_G.UpdateChatWindow = UpdateChatWindow
_G.ClearResults = ClearResults

