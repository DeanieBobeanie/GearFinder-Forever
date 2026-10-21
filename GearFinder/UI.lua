local _, G = ...
local safe = G.Safe
local gold = {0.93,0.77,0.43}
local colors = {[1]={1,1,1},[2]={0.2,1,0.2},[3]={0.3,0.6,1},[4]={0.75,0.4,1},[5]={1,0.5,0}}
local function text(parent,size)
    local fs = parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlight")
    fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(true)
    return fs
end
local function background(frame,r,g,b,a)
    local t = frame:CreateTexture(nil,"BACKGROUND")
    t:SetAllPoints(); t:SetColorTexture(r,g,b,a or 1)
    return t
end
local function button(parent,label,width,action)
    local b = CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,25); b:SetText(label); b:SetScript("OnClick",action)
    return b
end
local function checkbox(parent,label,x,y,key)
    local b = CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetSize(24,24); b:SetPoint("TOPLEFT",x,y); b:SetChecked(G.db[key])
    local t = text(b,"GameFontHighlightSmall"); t:SetPoint("LEFT",b,"RIGHT",2,0); t:SetText(label)
    b:SetScript("OnClick",function(self) G.db[key]=self:GetChecked() and true or false; G.Scan() end)
    return b
end
local function dropdown(parent,width,entries,selected,action)
    local b = button(parent,"",width,function() end)
    local menu = CreateFrame("Frame",nil,b,"BackdropTemplate")
    menu:SetSize(width,30); menu:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,-2)
    menu:SetFrameStrata("DIALOG"); menu:EnableMouse(true); background(menu,0.09,0.10,0.12)
    menu:Hide(); b.menu=menu
    b:SetScript("OnClick",function()
        if menu:IsShown() then menu:Hide(); return end
        if G.openMenu then G.openMenu:Hide() end
        G.openMenu=menu; menu:Show()
    end)
    b.SetChoices = function(_,list,value)
        entries=list
        for _, old in ipairs(menu.buttons or {}) do old:Hide() end
        menu.buttons=menu.buttons or {}
        for i,entry in ipairs(list) do
            local row=menu.buttons[i] or button(menu,"",width-8,function() end)
            menu.buttons[i]=row; row:SetPoint("TOPLEFT",4,-4-(i-1)*26); row:SetText(entry[2]); row:Show()
            local id=entry[1]
            row:SetScript("OnClick",function() menu:Hide(); b:SetText(entry[2] .. "  v"); action(id) end)
            if value==id then b:SetText(entry[2] .. "  v") end
        end
        menu:SetHeight(#list*26+8)
    end
    b:SetChoices(entries,selected)
    b:SetScript("OnHide",function() menu:Hide() end)
    return b
end
function G.HideTooltip()
    if not G.hover then return end
    if GameTooltip and safe(GameTooltip.GetOwner,GameTooltip)==G.hover.owner then
        safe(GameTooltip_HideShoppingTooltips,GameTooltip)
        for _, tip in pairs(GameTooltip.shoppingTooltips or {}) do safe(tip.Hide,tip) end
        GameTooltip:Hide()
    end
    G.hover=nil
end
function G.Tooltip(owner,item)
    if not GameTooltip or not item then return end
    G.hover={owner=owner,item=item}
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    local name,link=safe(C_Item and C_Item.GetItemInfo or GetItemInfo,item.id)
    local ok = GameTooltip.SetHyperlink and pcall(GameTooltip.SetHyperlink,GameTooltip,link or "item:"..item.id)
    if not name or not ok then
        GameTooltip:SetText(item.name)
        GameTooltip:AddLine("Loading live tooltip. The list uses bundled item stats.",1,0.8,0.4,true)
        safe(C_Item and C_Item.RequestLoadItemDataByID,item.id)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Base-stat ranking. Read procs, set bonuses and red requirements.",0.8,0.8,0.8,true)
    GameTooltip:Show()
    if name and ok then safe(GameTooltip_ShowCompareItem,GameTooltip) end
end
local tooltipEvents=CreateFrame("Frame")
safe(tooltipEvents.RegisterEvent,tooltipEvents,"GET_ITEM_INFO_RECEIVED")
safe(tooltipEvents.RegisterEvent,tooltipEvents,"ITEM_DATA_LOAD_RESULT")
tooltipEvents:SetScript("OnEvent",function(_,_,id)
    if G.hover and G.hover.item.id==id then
        local h=G.hover
        if h.owner:IsShown() then G.Tooltip(h.owner,h.item) end
    end
end)
local function bindTooltip(owner,getter)
    owner:SetScript("OnEnter",function(self) G.Tooltip(self,getter()) end)
    owner:SetScript("OnLeave",G.HideTooltip)
    owner:SetScript("OnHide",G.HideTooltip)
    owner.UpdateTooltip=function() if G.hover and G.hover.owner==owner then G.Tooltip(owner,getter()) end end
end
local function url(value)
    G.url:SetText(value); G.url:SetFocus(); G.url:HighlightText()
end
local function statsText(item)
    local parts={}
    for key,value in pairs(item.stats) do
        if value~=0 then parts[#parts+1]={key,(G.statNames[key] or "Stat "..key) .. " " .. value} end
    end
    table.sort(parts,function(a,b) return a[1]<b[1] end)
    local out={}
    for _,p in ipairs(parts) do out[#out+1]=p[2] end
    if item.armor>0 then out[#out+1]="Armor " .. item.armor end
    if item.damage and item.damage[3]>0 then out[#out+1]=string.format("Weapon DPS %.1f",(item.damage[1]+item.damage[2])/2/(item.damage[3]/1000)) end
    return #out>0 and table.concat(out,"\n") or "No scored base stats recorded"
end
function G.Detail(candidate)
    G.selected=candidate
    if G.partyLink then G.partyLink:SetEnabled(candidate~=nil) end
    if not candidate then G.detailText:SetText("Click an item to see its sources and requirements.\n\nHover an item for WoW's equipment comparison."); return end
    local item=candidate.item
    local lines={"|cffffd174"..item.name.."|r", "Required level "..item.level.." / item level "..item.ilvl,
        string.format("Score %.1f for %s",candidate.score,G.GetProfile().name), "",statsText(item),""}
    local c=G.results.character
    if c.currentLevel and c.level~=c.currentLevel then
        lines[#lines+1]="Planning at level "..c.level..". Equipment, profession skills and quest progress are from your current character."
    end
    local equipped=G.results.character.equipped[candidate.slot]
    if equipped and equipped.item then
        local score=G.Score(equipped.item,G.results.weights)
        lines[#lines+1]="Equipped: "..equipped.item.name
        lines[#lines+1]=string.format("Base-score difference %+.1f",candidate.score-score)
    elseif equipped then lines[#lines+1]="Equipped item has no bundled stats. Hover to compare."
    else lines[#lines+1]="This equipment slot is empty." end
    if item.slot==17 or candidate.slot==17 then lines[#lines+1]="Two-handed weapons replace both hands. Compare the full weapon setup." end
    if item.slot==11 or item.slot==12 then lines[#lines+1]="Both slots share the candidate list. Check Unique and Unique-Equipped restrictions." end
    if item.random then lines[#lines+1]="Random suffix stats are not included in this score." end
    if item.specialRequirements then lines[#lines+1]="Additional item requirements need checking in the live tooltip." end
    if item.setID and item.setID>0 then lines[#lines+1]="Set bonuses are not scored." end
    for _,fx in ipairs(item.effects) do lines[#lines+1]="Unscored effect: "..fx.text end
    lines[#lines+1]=""
    for i,entry in ipairs(candidate.sources) do
        lines[#lines+1]="|cffffd174"..i..". "..G.SourceText(entry).."|r"
        lines[#lines+1]=entry.status
        local s=entry.source
        if s.kind=="quest" then
            lines[#lines+1]="Quest ID "..s.quest
            local q=G.quests[s.quest]
            if q and q.zone then lines[#lines+1]="Area: "..q.zone end
            if q and q.classic and not s.classic then lines[#lines+1]="Quest requirements use Classic data." end
        elseif s.kind=="craft" then
            lines[#lines+1]="Recipe spell "..s.spell.." / "..(s.how or "learning source unknown")
            if #s.recipes>0 then lines[#lines+1]="Teaching item IDs: "..table.concat(s.recipes,", ") end
        end
        if s.chance then lines[#lines+1]=string.format("Classic drop chance %.2f%%. Forever may differ.",s.chance) end
        lines[#lines+1]=""
    end
    G.detailText:SetText(table.concat(lines,"\n"))
    G.detailBody:SetHeight(math.max(400,G.detailText:GetStringHeight()+20))
    G.detailScroll:SetVerticalScroll(0)
    G.url:SetText("https://forever-codex.com/items/?id="..item.id)
end
function G.UpdateLevelControls()
    if not G.levelInput then return end
    local level=G.ScanLevel()
    G.levelInput:SetText(tostring(level))
    G.levelDown:SetEnabled(level>1)
    G.levelUp:SetEnabled(level<60)
    G.levelCurrent:SetText(G.scanLevel and "Current" or "Current *")
end
function G.CommitLevelInput()
    local input=(G.levelInput:GetText() or ""):match("^%s*(.-)%s*$")
    if input=="" then return G.SetScanLevel(nil) end
    local value=tonumber(input)
    if value and value==G.ScanLevel() then G.UpdateLevelControls(); return true end
    if value and G.SetScanLevel(value) then return true end
    G.UpdateLevelControls()
    G.Print("Enter a whole level from 1 to 60, or click Current.")
    return false
end
function G.Refresh()
    if not G.frame then return end
    local c=G.results and G.results.character or G.Character()
    G.UpdateLevelControls()
    local levels="Level "..(c.currentLevel or c.level)
    if c.currentLevel and c.level~=c.currentLevel then levels=levels.."  /  Planning level "..c.level end
    G.heading:SetText("Gear Finder  /  "..(safe(UnitName,"player") or c.class).."  /  "..(c.faction or "Faction unknown").."  /  "..levels)
    if not G.results then G.status:SetText("Choose a role and click Scan."); return end
    G.HideTooltip()
    for _, row in ipairs(G.rows or {}) do row:Hide() end
    G.rows=G.rows or {}
    G.headers=G.headers or {}; G.itemRows=G.itemRows or {}
    local y=0
    for _,slot in ipairs(G.slots) do
        local header=G.headers[slot[1]]
        if not header then header=CreateFrame("Frame",nil,G.listBody); header.label=text(header); G.headers[slot[1]]=header; G.rows[#G.rows+1]=header end
        header:Show(); header:SetSize(592,30); header:ClearAllPoints(); header:SetPoint("TOPLEFT",0,-y)
        header.label:SetPoint("TOPLEFT",8,-8); header.label:SetWidth(570); header.label:SetTextColor(unpack(gold))
        local current=c.equipped[slot[1]]
        header.label:SetText(slot[2].."  |  "..(current and (current.item and current.item.name or "Item "..current.id) or "Empty"))
        y=y+32
        local candidates=G.results.slots[slot[1]]
        G.itemRows[slot[1]]=G.itemRows[slot[1]] or {}
        for rank=1,G.results.count do
            local row=G.itemRows[slot[1]][rank]
            if not row then
                row=CreateFrame("Button",nil,G.listBody); G.itemRows[slot[1]][rank]=row; G.rows[#G.rows+1]=row
                background(row,0.09,0.10,0.12)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
                row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("LEFT",8,0)
                row.name=text(row); row.name:SetPoint("TOPLEFT",48,-7); row.name:SetWidth(440)
                row.source=text(row,"GameFontHighlightSmall"); row.source:SetPoint("TOPLEFT",48,-26); row.source:SetWidth(510)
                safe(row.name.SetMaxLines,row.name,1); safe(row.source.SetMaxLines,row.source,1)
                row.score=text(row,"GameFontHighlightSmall"); row.score:SetPoint("TOPRIGHT",-8,-7); row.score:SetJustifyH("RIGHT"); row.score:SetWidth(84)
                bindTooltip(row,function() return row.candidate and row.candidate.item end)
                row:SetScript("OnClick",function(self)
                    if self.candidate then
                        G.Detail(self.candidate)
                        if safe(IsModifiedClick,"CHATLINK") or safe(IsShiftKeyDown) then G.LinkToParty(self.candidate.item) end
                    end
                end)
            end
            row.candidate=candidates[rank]; row:SetSize(592,46); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-y)
            local candidate=row.candidate
            if candidate then
                local item=candidate.item; local color=colors[item.quality] or colors[1]
                row.name:SetText(rank..". "..item.name); row.name:SetTextColor(unpack(color)); row.icon:SetTexture(item.icon or 134400)
                row.source:SetText(G.SourceText(candidate.sources[1])..(#candidate.sources>1 and " +"..(#candidate.sources-1).." routes" or ""))
                row.score:SetText(string.format("%.1f",candidate.score))
            else
                row.name:SetText(rank==1 and "No matching source recorded for these filters" or "No further matching item")
                row.name:SetTextColor(0.5,0.5,0.5); row.icon:SetTexture(nil); row.source:SetText(""); row.score:SetText("")
            end
            row:Show(); y=y+49
        end
        y=y+9
    end
    G.listBody:SetHeight(y)
    G.status:SetText(string.format("%d matching items / %d with sources / %d gear records. Snapshot %s.",
        G.results.eligible,G.results.sourced,#G.items,G.dataInfo.build))
    G.Detail(nil)
end
local function weightsWindow()
    if G.weightsFrame then G.weightsFrame:Hide(); G.weightsFrame=nil end
    local f=CreateFrame("Frame",nil,G.frame,"BackdropTemplate"); G.weightsFrame=f
    f:SetSize(400,540); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true)
    background(f,0.06,0.065,0.08)
    local title=text(f,"GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("Weights / "..G.GetProfile().name)
    local hint=text(f,"GameFontHighlightSmall"); hint:SetPoint("TOPLEFT",16,-43); hint:SetWidth(360)
    hint:SetText("One stat point adds this much to the score. These values are estimates. Zero ignores a stat.")
    local sf=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT",16,-85); sf:SetSize(340,385)
    local body=CreateFrame("Frame",nil,sf); body:SetSize(335,1000); sf:SetScrollChild(body)
    local keys={}; for key in pairs(G.statNames) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local fields,weights={},G.Weights(G.GetProfile())
    for i,key in ipairs(keys) do
        local name=text(body); name:SetPoint("TOPLEFT",0,-(i-1)*31); name:SetText(G.statNames[key])
        local input=CreateFrame("EditBox",nil,body,"InputBoxTemplate"); input:SetSize(80,24); input:SetPoint("TOPLEFT",230,-(i-1)*31+4)
        input:SetAutoFocus(false); input:SetText(tostring(weights[key] or 0)); input:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        fields[key]=input
    end
    body:SetHeight(#keys*31)
    local save=button(f,"Save",90,function()
        local custom={}
        for key,input in pairs(fields) do
            local value=tonumber(input:GetText())
            if not value or value~=value or math.abs(value)>10000 then hint:SetText("Enter a number between -10000 and 10000 in each field."); return end
            custom[key]=value
        end
        G.db.weights[G.GetProfile().id]=custom; f:Hide(); G.Scan()
    end); save:SetPoint("BOTTOMLEFT",16,17)
    local reset=button(f,"Reset",90,function() G.db.weights[G.GetProfile().id]=nil; f:Hide(); G.Scan() end); reset:SetPoint("LEFT",save,"RIGHT",12,0)
    local close=button(f,"Cancel",90,function() f:Hide() end); close:SetPoint("LEFT",reset,"RIGHT",12,0)
end
function G.Show()
    if G.frame then G.frame:Show(); return end
    local f=CreateFrame("Frame","GearFinderFrame",UIParent,"BackdropTemplate"); G.frame=f
    f:SetSize(1000,680); f:SetPoint("CENTER"); f:SetClampedToScreen(true); f:SetFrameStrata("HIGH")
    local screenWidth=safe(UIParent.GetWidth,UIParent) or 1200
    local screenHeight=safe(UIParent.GetHeight,UIParent) or 800
    f:SetScale(math.min(1,(screenWidth-24)/1000,(screenHeight-24)/680))
    background(f,0.045,0.05,0.065)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        local point,_,relative,x,y=self:GetPoint(); G.db.position={point,relative,x,y}
    end)
    if G.db.position then local p=G.db.position; f:ClearAllPoints(); f:SetPoint(p[1],UIParent,p[2],p[3],p[4]) end
    f:SetScript("OnHide",function() G.HideTooltip(); if G.openMenu then G.openMenu:Hide() end end)
    UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="GearFinderFrame"
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
    close:SetScript("OnClick",function() f:Hide() end)
    G.heading=text(f,"GameFontNormalLarge"); G.heading:SetPoint("TOPLEFT",16,-16); G.heading:SetWidth(930)
    local intro=text(f,"GameFontHighlightSmall"); intro:SetPoint("TOPLEFT",16,-43)
    intro:SetText("Best score first. Procs, set bonuses and random suffixes need a separate comparison.")
    G.countButton=dropdown(f,180,{{3,"Top 3 per slot"},{5,"Top 5 per slot"}},G.db.resultCount,function(count) G.db.resultCount=count; G.Scan() end)
    G.countButton:SetPoint("TOPLEFT",802,-36)
    local choices={}
    for _,id in ipairs(G.profileOrder) do local p=G.profiles[id]; if p.class==G.class then choices[#choices+1]={id,p.name} end end
    G.profileButton=dropdown(f,210,choices,G.db.profile,function(id) G.db.profile=id; G.Scan() end); G.profileButton:SetPoint("TOPLEFT",16,-68)
    local weapon=dropdown(f,210,{{"profile","Weapons for this role"},{"any","All usable weapons"},{"two","Two-handed"},{"dual","Dual wield"},{"shield","Weapon and shield"}},G.db.weapon,function(id) G.db.weapon=id; G.Scan() end)
    weapon:SetPoint("LEFT",G.profileButton,"RIGHT",10,0)
    local weights=button(f,"Edit stat weights",150,weightsWindow); weights:SetPoint("LEFT",weapon,"RIGHT",10,0)
    local levelLabel=text(f,"GameFontHighlightSmall"); levelLabel:SetPoint("TOPLEFT",618,-75); levelLabel:SetText("Level")
    G.levelDown=button(f,"-",24,function() G.SetScanLevel(math.max(1,G.ScanLevel()-1)) end)
    G.levelDown:SetPoint("TOPLEFT",658,-68)
    G.levelInput=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); G.levelInput:SetSize(36,24); G.levelInput:SetPoint("TOPLEFT",694,-68)
    G.levelInput:SetAutoFocus(false)
    G.levelInput:SetScript("OnEnterPressed",function(self) G.CommitLevelInput(); self:ClearFocus() end)
    G.levelInput:SetScript("OnEditFocusLost",function() G.CommitLevelInput() end)
    G.levelInput:SetScript("OnEscapePressed",function(self) G.UpdateLevelControls(); self:ClearFocus() end)
    G.levelUp=button(f,"+",24,function() G.SetScanLevel(math.min(60,G.ScanLevel()+1)) end)
    G.levelUp:SetPoint("TOPLEFT",738,-68)
    G.levelCurrent=button(f,"Current",72,function() G.SetScanLevel(nil) end)
    G.levelCurrent:SetPoint("TOPLEFT",770,-68)
    local scan=button(f,"Scan",130,function() if G.CommitLevelInput() then G.Scan() end end); scan:SetPoint("TOPRIGHT",-18,-68)
    checkbox(f,"Dungeons",16,-104,"dungeon"); checkbox(f,"Quests",133,-104,"quest"); checkbox(f,"Crafting",230,-104,"craft")
    checkbox(f,"Include Classic sources",342,-104,"classic"); checkbox(f,"Include uncertain requirements",554,-104,"uncertain")
    G.armorButton=dropdown(f,180,{{"all","All usable armor"},{"cloth","Cloth only"},{"leather","Leather only"},{"mail","Mail only"},{"plate","Plate only"}},G.db.armor,function(id) G.db.armor=id; G.Scan() end)
    G.armorButton:SetPoint("TOPLEFT",802,-104)
    checkbox(f,"Include commissions of tradable crafts",16,-134,"commission")
    local inspect=button(f,"Item lookup",130,function() G.ShowSources() end); inspect:SetPoint("TOPLEFT",375,-134)
    G.factionFarmingCheck=checkbox(f,"Use faction farming preferences",520,-134,"factionFarming")
    G.factionFarmingCheck:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText("Faction farming preferences")
        GameTooltip:AddLine("When checked, hides Ragefire Chasm for Alliance and Ruins of Lordaeron for Horde. These are optional farming preferences, not dungeon entrance rules.",1,1,1,true)
        GameTooltip:Show()
    end)
    G.factionFarmingCheck:SetScript("OnLeave",function() GameTooltip:Hide() end)
    G.listScroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); G.listScroll:SetPoint("TOPLEFT",16,-174); G.listScroll:SetSize(596,445)
    G.listBody=CreateFrame("Frame",nil,G.listScroll); G.listBody:SetSize(592,445); G.listScroll:SetScrollChild(G.listBody)
    G.detailScroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); G.detailScroll:SetPoint("TOPLEFT",655,-174); G.detailScroll:SetSize(308,355)
    G.detailBody=CreateFrame("Frame",nil,G.detailScroll); G.detailBody:SetSize(305,395); G.detailScroll:SetScrollChild(G.detailBody)
    G.detailText=text(G.detailBody); G.detailText:SetPoint("TOPLEFT",0,0); G.detailText:SetWidth(298)
    G.partyLink=button(f,"Link to party",150,function() G.LinkToParty(G.selected and G.selected.item) end)
    G.partyLink:SetPoint("TOPLEFT",651,-540)
    local partyHint=text(f,"GameFontHighlightSmall"); partyHint:SetPoint("TOPLEFT",811,-547); partyHint:SetText("Press Enter to send.")
    local source=button(f,"Item page",94,function() if G.selected then url("https://forever-codex.com/items/?id="..G.selected.item.id) end end); source:SetPoint("TOPLEFT",651,-580)
    local quest=button(f,"Quest page",100,function()
        if G.selected then
            for _,s in ipairs(G.selected.sources) do if s.source.quest then url("https://www.wowhead.com/forever/quest="..s.source.quest); return end end
            G.Print("This item has no quest source in the current results.")
        end
    end); quest:SetPoint("LEFT",source,"RIGHT",6,0)
    local coverage=button(f,"Coverage",100,function()
        G.detailText:SetText("Database coverage\n\n"..G.dataInfo.count.." gear records. "..G.dataInfo.sourced.." have a dungeon, quest or crafting source.\n\nSnapshot "..G.dataInfo.build.."\n\nDungeon drops use Classic records. New Forever dungeon drops are not included. Items without a recorded source do not appear.\n\nScan reads this bundled snapshot. It does not browse websites or update the database.\n\nRequirements may omit quest chains, reputation, weapon training and recipe unlocks. Check the item and source before farming.\n\nScores use base stats and your chosen weights. Each slot ranks independently, so the list is not an optimized full gear set.")
        G.detailBody:SetHeight(math.max(395,G.detailText:GetStringHeight()+20)); G.detailScroll:SetVerticalScroll(0)
    end); coverage:SetPoint("LEFT",quest,"RIGHT",6,0)
    G.url=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); G.url:SetPoint("TOPLEFT",657,-616); G.url:SetSize(312,22); G.url:SetAutoFocus(false)
    G.url:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    G.url:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    local copy=text(f,"GameFontHighlightSmall"); copy:SetPoint("TOPLEFT",655,-642); copy:SetText("Click a page button, then Ctrl+C to copy its URL.")
    G.status=text(f,"GameFontHighlightSmall"); G.status:SetPoint("BOTTOMLEFT",16,18); G.status:SetWidth(625)
    G.Detail(nil); G.Refresh(); f:Show()
end
