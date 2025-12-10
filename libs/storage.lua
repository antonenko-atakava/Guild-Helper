--- Библиотека для работы с хранилищем данных
-- @module libs.storage

--- Сохраняет позицию окна
-- @param frame table Фрейм
-- @param position_key string Ключ для сохранения
local function SaveFramePosition(frame, position_key)
    if not frame or not GuildHelperDB then
        return
    end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    GuildHelperDB[position_key] = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
    }
end

--- Загружает позицию окна
-- @param frame table Фрейм
-- @param position_key string Ключ для загрузки
local function LoadFramePosition(frame, position_key)
    if not frame or not GuildHelperDB or not GuildHelperDB[position_key] then
        return
    end
    
    local pos = GuildHelperDB[position_key]
    if pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
    end
end

--- Инициализирует базу данных с настройками по умолчанию
local function InitializeDatabase()
    if not GuildHelperDB then
        GuildHelperDB = {}
    end
    
    local defaults = GuildHelperConfig.DEFAULTS
    
    -- Слияние с настройками по умолчанию
    for k, v in pairs(defaults) do
        if GuildHelperDB[k] == nil then
            GuildHelperDB[k] = v
        end
    end
end

--- Экспорт функций модуля
_G.GuildHelperStorage = {
    SaveFramePosition = SaveFramePosition,
    LoadFramePosition = LoadFramePosition,
    InitializeDatabase = InitializeDatabase,
}

