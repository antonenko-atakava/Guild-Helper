--- Модуль кнопки миникарты для Guild Helper
-- @module modules.minimap

local config = GuildHelperConfig
local ADDON_NAME = config.ADDON_NAME
local VERSION = config.CONSTANTS.VERSION

-- Локализация глобальных функций
local math_cos = math.cos
local math_sin = math.sin
local math_atan2 = math.atan2

-- Создание кнопки миникарты
local minimap_button = CreateFrame("Button", "GuildHelperMinimapButton", Minimap)
minimap_button:SetFrameStrata("MEDIUM")
minimap_button:SetWidth(32)
minimap_button:SetHeight(32)
minimap_button:SetFrameLevel(8)
minimap_button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimap_button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Иконка кнопки
local icon = minimap_button:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")

-- Граница кнопки
local overlay = minimap_button:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetPoint("TOPLEFT")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

--- Обновляет позицию кнопки на миникарте
local function UpdatePosition()
    local angle = GuildHelperDB.minimapAngle or 200
    local x = math_cos(angle)
    local y = math_sin(angle)
    local dist = 80
    
    minimap_button:SetPoint("CENTER", Minimap, "CENTER", x * dist, y * dist)
end

--- Обработчик начала перетаскивания
local function OnDragStart(self)
    self:LockHighlight()
    self.isMoving = true
end

--- Обработчик окончания перетаскивания
local function OnDragStop(self)
    self:UnlockHighlight()
    self.isMoving = false
end

--- Обработчик обновления позиции при перетаскивании
-- @param self frame Фрейм кнопки
local function OnUpdate(self)
    if self.isMoving then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        
        local angle = math_atan2(py - my, px - mx)
        GuildHelperDB.minimapAngle = angle
        UpdatePosition()
    end
end

--- Обработчик кликов по кнопке
-- @param self frame Фрейм кнопки
-- @param button string Название кнопки мыши
local function OnClick(self, button)
    if button == "LeftButton" then
        -- Левая кнопка - открыть главное окно
        if GuildHelperUI then
            GuildHelperUI.ToggleMainFrame()
        end
    elseif button == "RightButton" then
        -- Правая кнопка - открыть окно чата
        if GuildHelperChatFrame then
            if GuildHelperChatFrame:IsVisible() then
                if GuildHelperUI then
                    GuildHelperUI.CloseChatWindow()
                end
            else
                if GuildHelperUI then
                    GuildHelperUI.OpenChatWindow()
                end
            end
        end
    end
end

--- Обработчик наведения мыши
-- @param self frame Фрейм кнопки
local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFFFF00Guild Helper|r", 1, 1, 1)
    GameTooltip:AddLine("v" .. VERSION, 0.5, 0.5, 0.5)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF00FF00ЛКМ:|r Открыть главное окно", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00ПКМ:|r Открыть журнал", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00Перетащить:|r Переместить кнопку", 1, 1, 1)
    GameTooltip:Show()
end

--- Обработчик ухода мыши
-- @param self frame Фрейм кнопки
local function OnLeave(self)
    GameTooltip:Hide()
end

--- Инициализирует кнопку миникарты
local function InitializeMinimapButton()
    -- Установка скриптов
    minimap_button:SetScript("OnDragStart", OnDragStart)
    minimap_button:SetScript("OnDragStop", OnDragStop)
    minimap_button:SetScript("OnUpdate", OnUpdate)
    minimap_button:SetScript("OnClick", OnClick)
    minimap_button:SetScript("OnEnter", OnEnter)
    minimap_button:SetScript("OnLeave", OnLeave)
    
    -- Регистрация перетаскивания
    minimap_button:RegisterForDrag("LeftButton")
    
    -- Установка начальной позиции
    if not GuildHelperDB.minimapAngle then
        GuildHelperDB.minimapAngle = 200
    end
    
    -- Возможность скрыть кнопку
    if GuildHelperDB.hideMinimapButton then
        minimap_button:Hide()
    else
        minimap_button:Show()
    end
    
    UpdatePosition()
end

--- Переключает видимость кнопки миникарты
local function Toggle()
    if minimap_button:IsVisible() then
        minimap_button:Hide()
        GuildHelperDB.hideMinimapButton = true
        print("|cFFFFFF00[GuildHelper]|r Кнопка миникарты скрыта. Используйте |cFFFFFF00/gh minimap|r для показа.")
    else
        minimap_button:Show()
        GuildHelperDB.hideMinimapButton = false
        print("|cFFFFFF00[GuildHelper]|r Кнопка миникарты показана.")
    end
end

-- Инициализация при входе в игру
local init_frame = CreateFrame("Frame")
init_frame:RegisterEvent("PLAYER_LOGIN")
init_frame:SetScript("OnEvent", InitializeMinimapButton)

--- Экспорт функций модуля
_G.GuildHelperMinimap = {
    Toggle = Toggle,
    UpdatePosition = UpdatePosition,
}

--- Глобальная функция для обратной совместимости
_G.GuildHelper_ToggleMinimapButton = Toggle

