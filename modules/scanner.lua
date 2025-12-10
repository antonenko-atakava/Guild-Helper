--- Модуль сканирования гильдии
-- @module modules.scanner

local config = GuildHelperConfig
local ADDON_NAME = config.ADDON_NAME

-- Локализация глобальных функций
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local GuildRoster = GuildRoster
local string_match = string.match
local table_sort = table.sort
local tinsert = table.insert

--- Сканирует членов гильдии без заметок
-- @param filter_online boolean Фильтровать только онлайн игроков
-- @param group_by_rank boolean Группировать по рангам
-- @return table, number Список членов без заметок и их количество
local function ScanMembersWithoutNotes(filter_online, group_by_rank)
    GuildRoster()
    
    local total_members = GetNumGuildMembers()
    if total_members == 0 then
        return nil, 0, 0
    end
    
    local members_without_notes = {}
    local count = 0
    
    for i = 1, total_members do
        local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline = GetGuildRosterInfo(i)
        
        -- Проверка на отсутствие или пустую заметку
        if not note or string_match(note, "^%s*$") then
            -- Фильтр по онлайн статусу
            if not filter_online or isOnline then
                count = count + 1
                
                local member_info = {
                    name = name or "Неизвестно",
                    level = level or 0,
                    class = class or "Неизвестно",
                    rank = rank or "Неизвестно",
                    rankIndex = rankIndex or 10,
                    isOnline = isOnline
                }
                
                tinsert(members_without_notes, member_info)
            end
        end
    end
    
    -- Сортировка по рангу, если нужно
    if group_by_rank then
        table_sort(members_without_notes, function(a, b)
            if a.rankIndex == b.rankIndex then
                return a.name < b.name
            end
            return a.rankIndex < b.rankIndex
        end)
    end
    
    return members_without_notes, count, total_members
end

--- Подсчитывает онлайн игроков в списке
-- @param members table Список членов гильдии
-- @return number Количество онлайн игроков
local function CountOnlineMembers(members)
    local online_count = 0
    
    for _, member in ipairs(members) do
        if member.isOnline then
            online_count = online_count + 1
        end
    end
    
    return online_count
end

--- Экспорт функций модуля
_G.GuildHelperScanner = {
    ScanMembersWithoutNotes = ScanMembersWithoutNotes,
    CountOnlineMembers = CountOnlineMembers,
}

