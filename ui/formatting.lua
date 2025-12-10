--- Модуль форматирования вывода
-- @module ui.formatting

-- Локализация глобальных функций
local string_format = string.format
local string_len = string.len
local string_sub = string.sub
local tinsert = table.insert
local tconcat = table.concat
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

--- Создает разделитель таблицы
-- @return string Разделитель
local function CreateTableDivider()
    return "+--------------------+------+-------------+----------------------+"
end

--- Создает заголовок таблицы
-- @return string Заголовок
local function CreateTableHeader()
    local header = "+--------------------+------+-------------+----------------------+"
    local titles = "| Имя                | Ур.  | Класс       | Ранг                 |"
    local divider = "+--------------------+------+-------------+----------------------+"
    return header .. "\n" .. titles .. "\n" .. divider
end

--- Создает строку таблицы
-- @param name string Имя игрока
-- @param level number Уровень
-- @param class string Класс
-- @param rank string Ранг
-- @param is_online boolean Онлайн статус
-- @return string Строка таблицы
local function CreateTableRow(name, level, class, rank, is_online)
    -- Обрезка длинных имен
    if string_len(name) > 18 then
        name = string_sub(name, 1, 15) .. "..."
    end
    if string_len(rank) > 20 then
        rank = string_sub(rank, 1, 17) .. "..."
    end
    if string_len(class) > 11 then
        class = string_sub(class, 1, 8) .. "..."
    end
    
    -- Форматирование с выравниванием
    local status_symbol = is_online and "*" or "o"
    local name_col = string_format(" %s %-17s", status_symbol, name)
    local level_col = string_format(" %-4d", level)
    local class_col = string_format(" %-11s", class)
    local rank_col = string_format(" %-20s", rank)
    
    return "|" .. name_col .. "|" .. level_col .. "|" .. class_col .. "|" .. rank_col .. "|"
end

--- Создает футер таблицы
-- @return string Футер
local function CreateTableFooter()
    return "+--------------------+------+-------------+----------------------+"
end

--- Форматирует список членов в виде таблицы
-- @param members table Список членов гильдии
-- @param group_by_rank boolean Группировать по рангам
-- @return table Массив строк таблицы
local function FormatMembersAsTable(members, group_by_rank)
    local lines = {}
    
    -- Заголовок таблицы
    tinsert(lines, "|cFF00AAFF" .. CreateTableHeader() .. "|r")
    
    if group_by_rank then
        -- Группировка по рангам
        local current_rank = nil
        for i, member in ipairs(members) do
            if member.rank ~= current_rank then
                if current_rank ~= nil then
                    -- Разделитель между группами
                    tinsert(lines, "|cFF888888+--------------------+------+-------------+----------------------+|r")
                end
                current_rank = member.rank
            end
            
            -- Цвет класса
            local class_color = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
            local color_str = string_format("|cFF%02x%02x%02x", 
                class_color.r * 255, 
                class_color.g * 255, 
                class_color.b * 255)
            
            local status_color = member.isOnline and "|cFF00FF00" or "|cFF808080"
            local row = CreateTableRow(member.name, member.level, member.class, member.rank, member.isOnline)
            tinsert(lines, status_color .. row .. "|r")
        end
    else
        -- Обычный список
        for i, member in ipairs(members) do
            local class_color = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
            local color_str = string_format("|cFF%02x%02x%02x", 
                class_color.r * 255, 
                class_color.g * 255, 
                class_color.b * 255)
            
            local status_color = member.isOnline and "|cFF00FF00" or "|cFF808080"
            local row = CreateTableRow(member.name, member.level, member.class, member.rank, member.isOnline)
            tinsert(lines, status_color .. row .. "|r")
        end
    end
    
    -- Футер таблицы
    tinsert(lines, "|cFF00AAFF" .. CreateTableFooter() .. "|r")
    
    return lines
end

--- Форматирует компактную таблицу для GUI
-- @param members table Список членов
-- @return table Массив строк
local function FormatMembersCompact(members)
    local lines = {}
    
    -- Заголовок таблицы для GUI
    tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
    tinsert(lines, "|cFF00AAFF| Имя        | Ур | Класс     | Ранг     ||r")
    tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
    
    for i, member in ipairs(members) do
        local status = member.isOnline and "*" or "o"
        local name = member.name
        if string_len(name) > 10 then
            name = string_sub(name, 1, 8) .. ".."
        end
        
        local class = member.class
        if string_len(class) > 9 then
            class = string_sub(class, 1, 7) .. ".."
        end
        
        local rank = member.rank
        if string_len(rank) > 8 then
            rank = string_sub(rank, 1, 6) .. ".."
        end
        
        -- Цвет класса
        local class_color = RAID_CLASS_COLORS[member.class] or {r = 1, g = 1, b = 1}
        local color_str = string_format("|cFF%02x%02x%02x", 
            class_color.r * 255, 
            class_color.g * 255, 
            class_color.b * 255)
        
        local status_color = member.isOnline and "|cFF00FF00" or "|cFF808080"
        
        tinsert(lines, string_format("|cFFFFFFFF| %s%s|r %-10s| %2d | %s%-9s|r | %-8s ||r", 
            status_color, status, name, member.level, color_str, class, rank))
    end
    
    tinsert(lines, "|cFF00AAFF+------------+----+-----------+----------+|r")
    
    return tconcat(lines, "\n")
end

--- Экспорт функций модуля
_G.GuildHelperFormatting = {
    FormatMembersAsTable = FormatMembersAsTable,
    FormatMembersCompact = FormatMembersCompact,
}

