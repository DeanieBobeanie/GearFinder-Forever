local _, G = ...
local safe = G.Safe

function G.ParseItemID(value)
    if type(value) == "number" then
        if value > 0 and value < 2147483647 and value == math.floor(value) then return value end
        return nil
    end
    if type(value) ~= "string" then return nil end
    local id = value:match("|Hitem:(%d+)[:|]") or value:match("^item:(%d+)[:|]?") or value:match("^%s*(%d+)%s*$")
    return id and G.ParseItemID(tonumber(id)) or nil
end

function G.LookupItem(value)
    local id = G.ParseItemID(value)
    if not id then return nil end
    local name, link = safe(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
    local item = G.byID[id]
    local supplied = type(value)=="string" and value:match("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h.-|h|r)")
        or type(value)=="string" and value:match("(|Hitem:.-|h.-|h)")
    G.sourceItemRequests=G.sourceItemRequests or {}
    if not name and not G.sourceItemRequests[id] then
        G.sourceItemRequests[id]=true
        safe(C_Item and C_Item.RequestLoadItemDataByID,id)
    end
    local linkedName=supplied and supplied:match("|h%[(.-)%]|h")
    return {id=id, name=name or linkedName or item and item.name or "Item "..id, link=supplied or link, record=item}
end

function G.LookupText(found)
    local item=found.record
    local lines={found.link or found.name, "Item ID "..found.id, "",
        "Recorded ways to obtain this item. The player's actual source is not known.", ""}
    if not item or #item.sources==0 then
        lines[#lines+1]="No acquisition source is recorded in this snapshot. This does not mean the item is unavailable."
    else
        local c=G.Character(); c.level=c.currentLevel
        local options={dungeon=true,quest=true,craft=true,classic=true,uncertain=false,commission=true,armor="all",weapon="any"}
        lines[#lines+1]="Required character level: "..item.level..". Your character level: "..c.level.."."
        if not G.CanEquip(item,c,options) then lines[#lines+1]="Your character does not meet the recorded equip requirements, or an extra requirement needs checking." end
        lines[#lines+1]="All recorded routes are shown, regardless of your scan filters."
        for i,source in ipairs(item.sources) do
            lines[#lines+1]="\n"..i..". "..G.SourceText({source=source})
            local status=G.SourceStatus(source,item,c,options)
            lines[#lines+1]=status or "Not eligible under your current character's recorded requirements or faction farming preferences. Check the requirements below."
            if source.kind=="dungeon" then
                local dungeon=G.dungeons[source.dungeon]
                if dungeon then lines[#lines+1]="Recommended dungeon levels: "..(dungeon.min or "unknown").."-"..(dungeon.max or "unknown") end
            elseif source.kind=="quest" then
                local q=G.quests[source.quest]
                lines[#lines+1]="Quest ID "..source.quest
                if q then
                    lines[#lines+1]="Quest minimum level: "..(q.min or "unknown")..". Faction: "..(q.faction or "both / not restricted in record")
                    if q.zone then lines[#lines+1]="Area: "..q.zone end
                    if q.previous and q.previous>0 then lines[#lines+1]="Prerequisite quest ID: "..q.previous end
                    if G.Completed(q.id,c) then lines[#lines+1]="Your character has completed this quest." end
                    if q.classMask or q.raceMask or q.requirements or q.skill then lines[#lines+1]="Check class, race and other quest restrictions on the quest page." end
                end
            elseif source.kind=="craft" then
                lines[#lines+1]="Profession: "..source.profession..". Skill: "..(source.skill or "unknown")
                lines[#lines+1]="Recipe spell ID: "..source.spell..". "..(source.how or "Recipe learning source unknown")
                if source.recipes and #source.recipes>0 then lines[#lines+1]="Teaching item IDs: "..table.concat(source.recipes,", ") end
            end
            local dungeon=source.dungeon or G.questDungeons[source.quest] or G.QuestDungeon(G.quests[source.quest])
            if not G.DungeonAllowed(dungeon,c.faction) then lines[#lines+1]="Excluded by your faction farming preference." end
            if source.chance then lines[#lines+1]=string.format("Classic drop chance %.2f%%. Forever may differ.",source.chance) end
        end
    end
    lines[#lines+1]="\nCoverage is incomplete. New Forever dungeon drops are not included. Classic routes may differ in Forever. Use Item page to research missing sources."
    return table.concat(lines,"\n")
end

local function inspectStatus(message)
    if G.inspectStatus then G.inspectStatus:SetText(message) end
end
function G.CancelInspect(message)
    G.inspectPending=nil
    if message then inspectStatus(message) end
end
function G.ReadInspectedGear(unit)
    local entries={}
    for _,slot in ipairs(G.slots) do
        local link=safe(GetInventoryItemLink,unit,slot[1])
        local id=G.ParseItemID(link) or safe(GetInventoryItemID,unit,slot[1])
        entries[#entries+1]={slot=slot[1],label=slot[2],item=id and G.LookupItem(link or id) or nil}
    end
    G.inspectedGear=entries
    if G.RenderInspectedGear then G.RenderInspectedGear() end
end
function G.InspectTarget()
    G.ShowSources()
    if G.inspectPending then inspectStatus("Waiting for the current inspection. Try again after it finishes."); return false end
    G.inspectedGear={}; G.RenderInspectedGear(); G.ShowItemSource(nil)
    local unit="target"
    if not safe(UnitIsPlayer,unit) or not safe(UnitGUID,unit) then
        inspectStatus("Target a nearby player, then click Inspect target."); return false
    end
    if safe(InCombatLockdown) then inspectStatus("Inspect after combat ends."); return false end
    if InspectFrame and InspectFrame.unit and safe(InspectFrame.IsShown,InspectFrame) and not safe(UnitIsUnit,InspectFrame.unit,unit) then
        inspectStatus("Close the game's Inspect window before inspecting a different player here."); return false
    end
    if not safe(CanInspect,unit,true) then inspectStatus("Move closer to the player and try again. This target cannot currently be inspected."); return false end
    local now=safe(GetTime) or 0
    if G.lastInspectRequest and now-G.lastInspectRequest<3 then inspectStatus("Wait a few seconds before inspecting again."); return false end
    local request={unit=unit,guid=safe(UnitGUID,unit),name=safe(UnitName,unit) or "Player"}
    G.inspectPending=request; G.lastInspectRequest=now
    inspectStatus("Loading gear for "..request.name.."...")
    if type(NotifyInspect)~="function" or not pcall(NotifyInspect,unit) then
        G.CancelInspect("Inspection is unavailable on this client."); return false
    end
    if C_Timer and C_Timer.After then C_Timer.After(8,function()
        if G.inspectPending==request then G.CancelInspect("Inspection timed out. Move closer and click Inspect target again.") end
    end) end
    return true
end

local events=CreateFrame("Frame")
for _,event in ipairs({"INSPECT_READY","PLAYER_TARGET_CHANGED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT"}) do safe(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event,value)
    if event=="INSPECT_READY" then
        local request=G.inspectPending
        if not request or request.guid~=value then return end
        if safe(UnitGUID,request.unit)~=request.guid then G.CancelInspect("Target changed. Inspect the new target to load its gear."); return end
        G.inspectPending=nil
        G.ReadInspectedGear(request.unit)
        inspectStatus("Gear for "..request.name..". Click an item for sources. Empty / unavailable slots have no item data.")
    elseif event=="PLAYER_TARGET_CHANGED" and G.inspectPending then
        G.CancelInspect("Target changed. Click Inspect target to load the new player's gear.")
    elseif event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
        if G.sourceFrame and G.sourceFrame:IsShown() then
            for _,entry in ipairs(G.inspectedGear or {}) do
                if entry.item and entry.item.id==value then entry.item=G.LookupItem(entry.item.link or value) end
            end
            G.RenderInspectedGear()
            if G.sourceItem and G.sourceItem.id==value then G.ShowItemSource(G.sourceItem.link or value) end
        end
    end
end)
