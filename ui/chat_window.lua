--- Модуль управления окном чата
-- @module ui.chat_window

local _G = _G

--- Инициализация окна чата
-- @param frame table Фрейм окна
local function InitializeChatWindow(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    
    local title = _G["GuildHelperChatFrame_Title"]
    if title then
        title:SetText("Guild Helper - Журнал")
    end
end

--- Обновляет содержимое окна чата
local function UpdateChatWindow()
    if not GuildHelperChatFrame then
        return
    end
    
    local scroll_frame = _G["GuildHelperChatFrame_ScrollFrame"]
    if not scroll_frame then
        return
    end
    
    local scroll_child = _G["GuildHelperChatFrame_ScrollFrame_ScrollChild"]
    if not scroll_child then
        return
    end
    
    local text = _G["GuildHelperChatFrame_ScrollFrame_ScrollChild_Text"]
    if not text then
        return
    end
    
    local messages_text = GuildHelperChatLog.GetMessagesText()
    text:SetText(messages_text)
    
    -- Прокрутка вниз
    scroll_frame:SetVerticalScroll(scroll_frame:GetVerticalScrollRange())
end

--- Открывает окно чата
local function OpenChatWindow()
    if not GuildHelperChatFrame then
        return
    end
    
    if GuildHelperStorage then
        GuildHelperStorage.LoadFramePosition(GuildHelperChatFrame, "chatPosition")
    end
    
    GuildHelperChatFrame:Show()
    UpdateChatWindow()
end

--- Закрывает окно чата
local function CloseChatWindow()
    if not GuildHelperChatFrame then
        return
    end
    
    if GuildHelperStorage then
        GuildHelperStorage.SaveFramePosition(GuildHelperChatFrame, "chatPosition")
    end
    
    GuildHelperChatFrame:Hide()
end

--- Экспорт функций модуля (расширяем существующий)
if not _G.GuildHelperUI then
    _G.GuildHelperUI = {}
end

_G.GuildHelperUI.InitializeChatWindow = InitializeChatWindow
_G.GuildHelperUI.UpdateChatWindow = UpdateChatWindow
_G.GuildHelperUI.OpenChatWindow = OpenChatWindow
_G.GuildHelperUI.CloseChatWindow = CloseChatWindow

