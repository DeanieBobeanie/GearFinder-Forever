local addonName, G = ...
_G.GearFinder = G
G.byID = {}
for _, item in ipairs(G.items) do G.byID[item.id] = item end

function G.Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a,b,c,d,e,f,g,h,i,j,k,l = pcall(fn, ...)
    if ok then return a,b,c,d,e,f,g,h,i,j,k,l end
end
local safe = G.Safe
function G.HasBit(value, mask)
    return value and mask and math.floor(value / mask) % 2 == 1
end
local function member(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true end end
    return false
end
local armorTypes = {cloth=1, leather=2, mail=3, plate=4}
local armorSlots = {[1]=true,[3]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[20]=true}
function G.Initialize()
    if type(GearFinderDB) ~= "table" then GearFinderDB = {} end
    G.db = GearFinderDB
    local defaults = { dungeon=true, quest=true, craft=true, classic=true, uncertain=false,
        commission=true, factionFarming=true, weapon="profile", armor="all", resultCount=3, known={}, weights={}, version=1 }
    for key, value in pairs(defaults) do if G.db[key] == nil then G.db[key] = value end end
    if G.db.armor ~= "all" and not armorTypes[G.db.armor] then G.db.armor = "all" end
    if G.db.resultCount ~= 5 then G.db.resultCount = 3 end
    if type(G.db.known) ~= "table" then G.db.known = {} end
    if type(G.db.weights) ~= "table" then G.db.weights = {} end
    local _, class = safe(UnitClass, "player")
    G.class = class or "WARRIOR"
    if not G.profiles[G.db.profile] or G.profiles[G.db.profile].class ~= G.class then
        for _, id in ipairs(G.profileOrder) do
            if G.profiles[id].class == G.class then G.db.profile = id; break end
        end
    end
end
function G.GetProfile()
    return G.profiles[G.db.profile] or G.profiles[G.profileOrder[1]]
end
function G.Weights(profile)
    local weights = {}
    for key, value in pairs(profile.weights) do weights[key] = value end
    for key, value in pairs(G.db.weights[profile.id] or {}) do weights[key] = value end
    return weights
end
function G.CurrentLevel()
    return math.max(1, math.min(60, G.playerLevel or tonumber(safe(UnitLevel,"player")) or 1))
end
function G.ScanLevel()
    return G.scanLevel or G.CurrentLevel()
end
function G.SetScanLevel(value)
    if value ~= nil and (type(value) ~= "number" or value ~= value or value < 1 or value > 60 or value ~= math.floor(value)) then
        return false
    end
    -- The override lasts for this session. A login or reload starts at current level.
    G.scanLevel = value
    if G.UpdateLevelControls then G.UpdateLevelControls() end
    G.Scan()
    return true
end
function G.ScanRecipes()
    local api = C_TradeSkillUI or {}
    if safe(IsTradeSkillLinked) or safe(api.IsTradeSkillLinked) or safe(api.IsTradeSkillGuild) or safe(api.IsNPCCrafting) then return end
    local ids = safe(api.GetAllRecipeIDs)
    for _, id in ipairs(ids or {}) do
        local info = safe(api.GetRecipeInfo, id)
        if info and info.learned then G.db.known[id] = true end
    end
    local count = safe(GetNumTradeSkills) or 0
    for i=1,count do
        local link = safe(GetTradeSkillRecipeLink, i)
        local id = link and (link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
        if id then G.db.known[tonumber(id)] = true end
    end
end
function G.Character()
    local c = {class=G.class, level=G.ScanLevel(), currentLevel=G.CurrentLevel(), faction=safe(UnitFactionGroup,"player"),
        skills={}, known=G.db.known, equipped={}, completed={}, raceID=select(3,safe(UnitRace,"player"))}
    local a,b,d,e,f = safe(GetProfessions)
    for _, index in pairs({a,b,d,e,f}) do
        local name, _, rank, _, _, _, skillID = safe(GetProfessionInfo,index)
        if skillID then c.skills[skillID] = rank end
        if name then c.skills[name] = rank end
    end
    for i=1,(safe(GetNumSkillLines) or 0) do
        local name, header, _, rank = safe(GetSkillLineInfo,i)
        if not header and name then c.skills[name] = rank end
    end
    for profession, id in pairs(G.professionIDs) do
        local spell = G.professionSpells[profession]
        local name = safe(C_Spell and C_Spell.GetSpellName,spell) or safe(GetSpellInfo,spell)
        c.skills[id] = c.skills[id] or c.skills[name or ""] or c.skills[profession:gsub("^%l",string.upper)]
    end
    for _, slot in ipairs(G.slots) do
        local id = safe(GetInventoryItemID,"player",slot[1])
        local link = safe(GetInventoryItemLink,"player",slot[1])
        if id then c.equipped[slot[1]] = {id=id, link=link, item=G.byID[id]} end
    end
    if not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then safe(GetQuestsCompleted,c.completed) end
    return c
end
function G.Completed(id, c)
    if c.completed[id] ~= nil then return c.completed[id] end
    local done = safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,id)
    if done == nil then done = safe(IsQuestFlaggedCompleted,id) end
    c.completed[id] = done or false
    return done
end
local function maxArmor(c)
    if c.class == "WARRIOR" or c.class == "PALADIN" then return c.level >= 40 and 4 or 3 end
    if c.class == "HUNTER" or c.class == "SHAMAN" then return c.level >= 40 and 3 or 2 end
    if c.class == "ROGUE" or c.class == "DRUID" then return 2 end
    return 1
end
function G.CanEquip(item,c,options)
    if item.level > c.level then return false end
    local classID = G.classIDs[c.class]
    if not classID then return false end
    if item.classMask and item.classMask > 0 and not G.HasBit(item.classMask,2^(classID-1)) then return false end
    if G.HasBit(item.flags,8) and c.faction ~= "Alliance" then return false end
    if G.HasBit(item.flags,16) and c.faction ~= "Horde" then return false end
    if item.requiredSkill then
        local skill, rank = item.requiredSkill[1], item.requiredSkill[2] or 1
        if (c.skills[skill] or 0) < rank then return false end
    end
    if item.specialRequirements and not options.uncertain then return false end
    if item.classID == 4 then
        if item.sub >= 1 and item.sub <= 4 and item.sub > maxArmor(c) then return false end
        local armor = armorTypes[options.armor]
        if armor and armorSlots[item.slot] and item.sub ~= armor then return false end
        if item.sub == 6 and not member({"WARRIOR","PALADIN","SHAMAN"},c.class) then return false end
        local relic = {[7]="PALADIN",[8]="DRUID",[9]="SHAMAN"}
        if relic[item.sub] and relic[item.sub] ~= c.class then return false end
    elseif item.classID == 2 and not member(G.weapons[c.class],item.sub) then return false end
    return true
end
function G.TargetSlots(item,c,profile,options)
    local inv = item.slot
    local weapon = options.weapon == "profile" and profile.weapon or options.weapon
    if weapon == "two" and (inv == 13 or inv == 14 or inv == 21 or inv == 22 or inv == 23) then return {} end
    if (weapon == "shield" or weapon == "dual" or weapon == "daggers" or weapon == "one") and inv == 17 then return {} end
    if weapon == "daggers" and item.classID == 2 and (inv == 13 or inv == 21 or inv == 22) and item.sub ~= 15 then return {} end
    if inv == 11 then return {11,12} end
    if inv == 12 then return {13,14} end
    if inv == 16 then return {15} end
    if inv == 20 then return {5} end
    if inv == 17 or inv == 21 then return {16} end
    if inv == 13 then
        local dual = c.class == "ROGUE" and c.level >= 10 or c.class == "WARRIOR" and c.level >= 20 or c.class == "HUNTER" and c.level >= 20
        if dual and weapon ~= "shield" and weapon ~= "one" then return {16,17} end
        return {16}
    end
    if inv == 14 or inv == 23 then
        if weapon == "dual" or weapon == "daggers" then return {} end
        if weapon == "shield" and inv ~= 14 then return {} end
        return {17}
    end
    if inv == 22 then
        if weapon == "shield" or weapon == "one" then return {} end
        if c.class == "ROGUE" and c.level >= 10 or c.class == "WARRIOR" and c.level >= 20 or c.class == "HUNTER" and c.level >= 20 then return {17} end
        return {}
    end
    if inv == 15 or inv == 25 or inv == 26 or inv == 28 then return {18} end
    if inv >= 1 and inv <= 10 and inv ~= 4 then return {inv} end
    return {}
end
function G.SourceStatus(source,item,c,options)
    if not options[source.kind] or source.classic and not options.classic then return nil end
    if not G.DungeonAllowed(source.dungeon,c.faction) then return nil end
    if source.kind == "dungeon" then
        local dungeon = G.dungeons[source.dungeon]
        if not dungeon or not dungeon.min then
            return options.uncertain and "Dungeon level not recorded" or nil
        end
        if c.level < dungeon.min then return nil end
        return "Group recommended. Dungeon levels " .. dungeon.min .. "-" .. dungeon.max
    elseif source.kind == "quest" then
        local q = G.quests[source.quest]
        if not G.DungeonAllowed(G.questDungeons[source.quest] or G.QuestDungeon(q),c.faction) then return nil end
        if not q or q.min == nil then return options.uncertain and "Quest requirements not recorded" or nil end
        if q.denied or q.kind == "raid" or q.kind == "pvp" or q.kind == "event" then return nil end
        if q.min > c.level or q.faction and q.faction ~= c.faction then return nil end
        if q.classic and not options.classic then return nil end
        if q.classMask and q.classMask > 0 and not G.HasBit(q.classMask,2^(G.classIDs[c.class]-1)) then return nil end
        if q.raceMask and q.raceMask > 0 and (not c.raceID or not G.HasBit(q.raceMask,2^(c.raceID-1))) then return nil end
        if (q.skill or q.requirements) and not options.uncertain then return nil end
        if G.Completed(q.id,c) and not q.repeatable then return nil end
        local predecessor, visited = q.previous, {}
        while predecessor and predecessor > 0 and not visited[predecessor] do
            visited[predecessor] = true
            if G.Completed(predecessor,c) then break end
            local previous = G.quests[predecessor]
            if not previous then break end
            if not G.DungeonAllowed(G.QuestDungeon(previous),c.faction) then return nil end
            if previous.min and previous.min > c.level then return nil end
            predecessor = previous.previous
        end
        if q.dungeon and G.dungeons[q.dungeon] and G.dungeons[q.dungeon].min > c.level then return nil end
        local status = "Quest level " .. q.level .. "; minimum " .. q.min
        if q.previous and q.previous > 0 and not G.Completed(q.previous,c) then status = status .. ". Start its prerequisite chain" end
        return status .. ". Check prerequisites and reward choices"
    elseif source.kind == "craft" then
        local skillID = G.professionIDs[source.profession]
        local rank = c.skills[skillID] or 0
        local known = c.known[source.spell] or safe(IsPlayerSpell,source.spell) or safe(IsSpellKnown,source.spell)
        if options.commission and (item.bind == 0 or item.bind == 2 or item.bind == 3) then
            return "Commission or craft. " .. source.name .. " " .. (source.skill or "skill unknown")
        end
        if rank == 0 then return nil end
        if not source.skill and not known then return options.uncertain and "Recipe skill unknown. Check your trainer" or nil end
        if source.skill and source.skill > rank then return nil end
        if item.bind == 1 and not known and not options.uncertain then return nil end
        return source.name .. " " .. (source.skill or "known recipe") .. ". " .. (known and "Recipe known; check materials" or "Recipe not confirmed learned")
    end
end
function G.Score(item,weights)
    local score = 0
    for stat,value in pairs(item.stats or {}) do score = score + value * (weights[stat] or 0) end
    score = score + (item.armor or 0) * (weights.armor or 0)
    local d = item.damage
    if d and d[3] and d[3] > 0 then
        local key = item.slot == 15 or item.slot == 25 or item.slot == 26
        score = score + ((d[1]+d[2])/2)/(d[3]/1000) * (weights[key and "rangedDPS" or "meleeDPS"] or 0)
    end
    return score
end
function G.Rank(c,options,profile)
    local result = {slots={}, eligible=0, sourced=0, character=c, profile=profile, weights=G.Weights(profile), count=options.resultCount==5 and 5 or 3}
    for _, s in ipairs(G.slots) do result.slots[s[1]] = {} end
    for _, item in ipairs(G.items) do
        if #item.sources > 0 then result.sourced = result.sourced + 1 end
        if G.CanEquip(item,c,options) then
            local slots = G.TargetSlots(item,c,profile,options)
            local sources = {}
            if #slots > 0 then
                for _, source in ipairs(item.sources) do
                    local status = G.SourceStatus(source,item,c,options)
                    if status then sources[#sources+1] = {source=source,status=status} end
                end
            end
            if #sources > 0 then
                result.eligible = result.eligible + 1
                local score = G.Score(item,result.weights)
                for _, slot in ipairs(slots) do
                    local list = result.slots[slot]
                    list[#list+1] = {item=item,score=score,sources=sources,slot=slot}
                end
            end
        end
    end
    for _, list in pairs(result.slots) do
        table.sort(list,function(a,b)
            if a.score ~= b.score then return a.score > b.score end
            if a.item.ilvl ~= b.item.ilvl then return a.item.ilvl > b.item.ilvl end
            return a.item.id < b.item.id
        end)
        while #list > result.count do table.remove(list) end
    end
    return result
end
function G.Scan()
    if G.scanning then return end
    G.scanning = true
    if G.status then G.status:SetText("Scanning the bundled database...") end
    local function finish()
        G.ScanRecipes()
        G.results = G.Rank(G.Character(),G.db,G.GetProfile())
        G.scanning = false
        G.stale = false
        if G.Refresh then G.Refresh() end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.03,finish) else finish() end
end
function G.ItemLink(item)
    local name, link = safe(C_Item and C_Item.GetItemInfo or GetItemInfo,item.id)
    if link then return link end
    return item.name
end
function G.SourceText(entry)
    local s = entry.source
    local text = s.kind == "dungeon" and s.name .. " / " .. s.boss
        or s.kind == "quest" and "Quest: " .. s.name or "Craft: " .. s.name
    if s.classic then text = text .. " [Classic data]" end
    return text
end
function G.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffedc66eGear Finder:|r " .. message) end
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,name)
    if event == "ADDON_LOADED" and name == addonName then
        G.Initialize()
        for _, ev in ipairs({"PLAYER_LEVEL_UP","PLAYER_EQUIPMENT_CHANGED","QUEST_TURNED_IN","SKILL_LINES_CHANGED","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE","UNIT_FACTION"}) do safe(events.RegisterEvent,events,ev) end
        SLASH_GEARFINDER1, SLASH_GEARFINDER2 = "/gear", "/gearfinder"
        SlashCmdList.GEARFINDER = function(msg)
            msg = (msg or ""):match("^%s*(.-)%s*$")
            local command,value=msg:match("^(%S+)%s*(.*)$")
            command=(command or ""):lower()
            if command=="item" then G.ShowSources(); if value~="" then G.ShowItemSource(value) end; return end
            if command=="inspect" then G.InspectTarget(); return end
            msg = msg:lower()
            if msg == "resetpos" then G.db.position=nil; G.Show(); G.frame:ClearAllPoints(); G.frame:SetPoint("CENTER"); return end
            if msg == "help" then G.Print("/gear opens the window. /gear scan rescans. /gear inspect inspects your target. /gear item <item link or ID> finds sources. /gear resetpos centers the ranking window."); return end
            if msg == "scan" then G.Show(); G.Scan(); return end
            if G.frame and G.frame:IsShown() then G.frame:Hide() else G.Show() end
        end
    elseif G.db then
        if event == "UNIT_FACTION" and name ~= "player" then return end
        if event == "PLAYER_LEVEL_UP" then
            G.playerLevel = tonumber(name) or G.CurrentLevel()
            if G.UpdateLevelControls then G.UpdateLevelControls() end
        end
        if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then G.ScanRecipes() end
        G.stale = true
        if G.status and G.frame:IsShown() then G.status:SetText("Character changed. Click Scan to update the results.") end
    end
end)
