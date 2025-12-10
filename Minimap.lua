-- Minimap.lua
-- Кнопка на миникарте для Guild Helper

local ADDON_NAME = "GuildHelper"

-- Создание кнопки миникарты
local minimapButton = CreateFrame("Button", "GuildHelperMinimapButton", Minimap)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Иконка кнопки
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")

-- Граница кнопки
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetPoint("TOPLEFT")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Позиция на миникарте
local function UpdatePosition()
    local angle = GuildHelperDB.minimapAngle or 200
    local x = math.cos(angle)
    local y = math.sin(angle)
    local dist = 80
    
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * dist, y * dist)
end

-- Перетаскивание кнопки
minimapButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self.isMoving = true
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self.isMoving = false
end)

minimapButton:SetScript("OnUpdate", function(self)
    if self.isMoving then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        
        local angle = math.atan2(py - my, px - mx)
        GuildHelperDB.minimapAngle = angle
        UpdatePosition()
    end
end)

-- Обработчик кликов
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Левая кнопка - открыть главное окно
        if GuildHelperFrame then
            if GuildHelperFrame:IsVisible() then
                GuildHelperFrame:Hide()
            else
                GuildHelperFrame_OnlineOnlyCheck:SetChecked(GuildHelperDB.onlineOnly)
                GuildHelperFrame_GroupByRankCheck:SetChecked(GuildHelperDB.groupByRank)
                GuildHelperFrame:Show()
                UpdateGUI()
            end
        end
    elseif button == "RightButton" then
        -- Правая кнопка - открыть окно чата
        if GuildHelperChatFrame then
            if GuildHelperChatFrame:IsVisible() then
                GuildHelperChatFrame:Hide()
            else
                GuildHelperChatFrame:Show()
                UpdateChatWindow()
            end
        end
    end
end)

-- Подсказка при наведении
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFFFF00Guild Helper|r", 1, 1, 1)
    GameTooltip:AddLine("v1.0.0", 0.5, 0.5, 0.5)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF00FF00ЛКМ:|r Открыть главное окно", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00ПКМ:|r Открыть журнал", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00Перетащить:|r Переместить кнопку", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Регистрация перетаскивания
minimapButton:RegisterForDrag("LeftButton")

-- Инициализация позиции
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    -- Установка начальной позиции
    if not GuildHelperDB.minimapAngle then
        GuildHelperDB.minimapAngle = 200
    end
    
    -- Возможность скрыть кнопку
    if GuildHelperDB.hideMinimapButton then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
    
    UpdatePosition()
end)

-- Глобальная функция для показа/скрытия кнопки
function GuildHelper_ToggleMinimapButton()
    if minimapButton:IsVisible() then
        minimapButton:Hide()
        GuildHelperDB.hideMinimapButton = true
        print("|cFFFFFF00[GuildHelper]|r Кнопка миникарты скрыта. Используйте |cFFFFFF00/gh minimap|r для показа.")
    else
        minimapButton:Show()
        GuildHelperDB.hideMinimapButton = false
        print("|cFFFFFF00[GuildHelper]|r Кнопка миникарты показана.")
    end
end

