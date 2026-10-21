local _, G = ...
-- Requested farming preferences, not claims about the game's entrance rules.
-- Keep these separate from generated data so a database refresh preserves them.
G.dungeonFarmingFactions = {
    ["ragefire-chasm"] = "Horde",
    ["ruins-of-lordaeron"] = "Alliance",
}
G.questDungeons = {}
for _, id in ipairs({5722,5723,5724,5725,5726,5727,5728,5729,5730,5761}) do
    G.questDungeons[id] = "ragefire-chasm"
end
for _, id in ipairs({92401,92421,92422,95216,95204,95189,97288,97289,97290,97291,97292}) do
    G.questDungeons[id] = "ruins-of-lordaeron"
end
function G.QuestDungeon(q)
    if not q then return nil end
    if G.questDungeons[q.id] then return G.questDungeons[q.id] end
    if q.dungeon then return q.dungeon end
    if G.dungeons[q.zone] then return q.zone end
    for slug, dungeon in pairs(G.dungeons) do
        if q.zone == dungeon.name then return slug end
    end
end
function G.DungeonAllowed(slug, faction)
    if G.db and G.db.factionFarming == false then return true end
    local required = slug and G.dungeonFarmingFactions[slug]
    return not required or faction == required
end
