G={}; frames={}; messages={}; timers={}; unpack=table.unpack
local methods={}
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:HookScript(event,fn)
    self.hookCounts=self.hookCounts or {}; self.hookCounts[event]=(self.hookCounts[event] or 0)+1
    local previous=self.scripts[event]
    self.scripts[event]=function(...) if previous then previous(...) end; fn(...) end
end
function methods:GetID() return self.id end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:SetText(value) self.text=tostring(value) end
function methods:GetText() return self.text or "" end
function methods:SetSize(w,h) self.w,self.h=w,h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetWidth() return self.w or 1920 end
function methods:GetHeight() return self.h or 1080 end
function methods:GetStringHeight() return math.ceil(#(self.text or "")/40)*16 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return "CENTER",UIParent,"CENTER",0,0 end
function methods:SetScrollChild(child) self.child=child end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:SetChecked(value) self.checked=value end
function methods:SetEnabled(value) self.enabled=value end
function methods:GetChecked() return self.checked end
function methods:SetTexture(value) self.texture=value end
function methods:SetOwner(owner) self.owner=owner end
function methods:GetOwner() return self.owner end
function methods:SetHyperlink(link) self.link=link end
for _,name in ipairs({"SetJustifyH","SetJustifyV","SetWordWrap","SetAllPoints","SetColorTexture","SetFrameStrata","EnableMouse","SetHighlightTexture","SetFontObject","SetTextColor","SetAutoFocus","ClearFocus","SetFocus","HighlightText","SetClampedToScreen","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","ClearAllPoints","SetScale","AddLine"}) do methods[name]=function() end end
function CreateFrame(kind,name,parent,template)
    local frame=setmetatable({kind=kind,name=name,parent=parent,template=template,events={},scripts={},shown=true},{__index=methods})
    frames[#frames+1]=frame
    if name then _G[name]=frame end
    return frame
end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
UIParent=CreateFrame("Frame"); GameTooltip=CreateFrame("GameTooltip")
SlashCmdList={}; UISpecialFrames={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) messages[#messages+1]=s end}
UnitClass=function() return "Mage","MAGE",8 end
UnitLevel=function() return 25 end
UnitFactionGroup=function() return "Alliance" end
UnitRace=function() return "Human","Human",1 end
UnitName=function() return "Testmage" end
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
function flush() while #timers>0 do local fn=table.remove(timers,1); fn() end end
-- LOAD ADDON HERE
for _,frame in ipairs(frames) do if frame.events.ADDON_LOADED then frame.scripts.OnEvent(frame,"ADDON_LOADED","GearFinder") end end
assert(SlashCmdList.GEARFINDER and G.db.profile=="MAGE:Frost")
assert(#G.items==G.dataInfo.count and #G.items>8000)
assert(#G.profileOrder==29)
local count=0
for id,item in pairs(G.byID) do
    count=count+1; assert(id>0 and item.name and type(item.stats)=="table")
    for _,source in ipairs(item.sources) do assert(source.name and (source.kind=="dungeon" or source.kind=="quest" or source.kind=="craft")) end
end
assert(count==#G.items,"Duplicate item IDs")
assert(G.byID[5191].name=="Cruel Barb" and G.byID[5191].damage[3]==2800)
assert(G.byID[2585].sources[1].spell==2403)
local function char(class,level,faction)
    return {class=class,level=level,faction=faction or "Alliance",skills={},known={},completed={},equipped={},raceID=1}
end
local c=char("MAGE",25)
assert(G.db.armor=="all","Existing settings default to all usable armor")
assert(G.db.factionFarming==true,"Keep existing farming preferences on by default")
assert(G.db.resultCount==3,"Existing characters default to three results")
G.db.resultCount=5; G.Initialize(); assert(G.db.resultCount==5)
G.db.resultCount=99; G.Initialize(); assert(G.db.resultCount==3,"Invalid result counts restore the default")
-- Armor choices narrow body armor without removing cloaks or other slots.
local bodySlots={1,3,5,6,7,8,9,10,20}
local types={"cloth","leather","mail","plate"}
for selected,name in ipairs(types) do
    G.db.armor=name
    for _,slot in ipairs(bodySlots) do
        for sub=1,4 do
            local item={level=1,classID=4,sub=sub,slot=slot}
            assert(G.CanEquip(item,char("WARRIOR",60),G.db)==(sub==selected))
        end
    end
    assert(G.CanEquip({level=1,classID=4,sub=1,slot=16},char("WARRIOR",60),G.db),"Cloaks stay visible")
    for _,slot in ipairs({2,11,12,23}) do
        assert(G.CanEquip({level=1,classID=4,sub=0,slot=slot},char("WARRIOR",60),G.db),"Jewelry and held items stay visible")
    end
    assert(G.CanEquip({level=1,classID=4,sub=6,slot=14},char("WARRIOR",60),G.db),"Shields stay visible")
    assert(G.CanEquip(G.byID[5191],char("WARRIOR",60),G.db),"Weapons stay visible")
end
G.db.armor="plate"
assert(not G.CanEquip({level=1,classID=4,sub=4,slot=5},char("WARRIOR",39),G.db))
assert(G.CanEquip({level=1,classID=4,sub=4,slot=5},char("WARRIOR",40),G.db))
assert(not G.CanEquip({level=1,classID=4,sub=4,slot=5},char("MAGE",60),G.db))
G.Initialize(); assert(G.db.armor=="plate","Armor choice survives initialization")
G.db.armor="invalid"; G.Initialize(); assert(G.db.armor=="all")
assert(not G.CanEquip(G.byID[5191],char("MAGE",18),G.db),"Level filter")
assert(not G.CanEquip(G.byID[6473],c,G.db),"Mage cannot equip leather")
assert(G.CanEquip(G.byID[2585],c,G.db),"Mage can equip robe")
assert(not G.CanEquip(G.byID[10502],c,G.db),"Engineering required even for a commissioned item")
c.skills[202]=215; assert(G.CanEquip(G.byID[10502],c,G.db))
local craft=G.byID[2585].sources[1]
G.db.commission=false
c.skills={}; assert(not G.SourceStatus(craft,G.byID[2585],c,G.db),"No personal profession")
c.skills[197]=79; assert(not G.SourceStatus(craft,G.byID[2585],c,G.db),"Skill too low")
c.skills[197]=80; assert(G.SourceStatus(craft,G.byID[2585],c,G.db),"Skill sufficient")
G.db.commission=true; c.skills={}; assert(G.SourceStatus(craft,G.byID[2585],c,G.db),"Tradable commission")
local source={kind="quest",name="Test quest",quest=999999}
G.quests[999999]={id=999999,name="Test quest",min=30,level=35,faction="Alliance",kind="leveling"}
assert(not G.SourceStatus(source,G.byID[2585],c,G.db),"Quest minimum level must gate a reward with no equip level")
G.quests[999999].min=20
assert(G.SourceStatus(source,G.byID[2585],c,G.db))
c.faction="Horde"; assert(not G.SourceStatus(source,G.byID[2585],c,G.db),"Quest faction restriction")
c.faction="Alliance"; c.completed[999999]=true; assert(not G.SourceStatus(source,G.byID[2585],c,G.db),"Completed reward not farmable")
c.completed={}; G.quests[999999].classMask=2; assert(not G.SourceStatus(source,G.byID[2585],c,G.db),"Class quest restriction")
G.quests[999999].classMask=nil; G.quests[999999].raceMask=4; assert(not G.SourceStatus(source,G.byID[2585],c,G.db),"Race restriction")
G.quests[999999]=nil
local drop=G.byID[5191].sources[1]
assert(drop.kind=="dungeon" and drop.classic)
assert(not G.SourceStatus(drop,G.byID[5191],char("ROGUE",10),G.db),"Dungeon recommended level filter")
G.db.classic=false; assert(not G.SourceStatus(drop,G.byID[5191],char("ROGUE",25),G.db))
G.db.classic=true
-- Apply the requested dungeon farming preferences to sources, not entire items.
local rfc={kind="dungeon",name="Ragefire Chasm",dungeon="ragefire-chasm",classic=true}
local rol={kind="dungeon",name="Ruins of Lordaeron",dungeon="ruins-of-lordaeron",classic=false}
local ally,horde=char("MAGE",25,"Alliance"),char("MAGE",25,"Horde")
assert(not G.SourceStatus(rfc,G.byID[2585],ally,G.db))
assert(G.SourceStatus(rfc,G.byID[2585],horde,G.db))
assert(G.SourceStatus(rol,G.byID[2585],ally,G.db))
assert(not G.SourceStatus(rol,G.byID[2585],horde,G.db))
assert(G.DungeonAllowed("deadmines","Alliance") and G.DungeonAllowed("deadmines","Horde"),"Do not invent restrictions for other dungeons")
assert(not G.DungeonAllowed("ragefire-chasm",nil),"Wait for a known faction")
G.db.uncertain=true
assert(not G.SourceStatus(rfc,G.byID[2585],ally,G.db) and not G.SourceStatus(rol,G.byID[2585],horde,G.db),"Uncertain requirements cannot bypass faction preferences")
G.quests[999998]={id=999998,name="Dungeon reward",min=1,level=10,kind="dungeon",dungeon="ruins-of-lordaeron"}
local dq={kind="quest",name="Dungeon reward",quest=999998}
assert(G.SourceStatus(dq,G.byID[2585],ally,G.db) and not G.SourceStatus(dq,G.byID[2585],horde,G.db))
G.quests[999998].dungeon=nil; G.quests[999998].zone="Ragefire Chasm"
assert(not G.SourceStatus(dq,G.byID[2585],ally,G.db) and G.SourceStatus(dq,G.byID[2585],horde,G.db),"Resolve dungeon names in quest zones")
assert(not G.SourceStatus({kind="quest",name="Unending Torment",quest=97292},G.byID[2585],horde,G.db),"Outside turn-ins still require their dungeon")
-- Disabling the preference exposes both dungeon routes without bypassing quest faction restrictions.
G.db.factionFarming=false; G.Initialize()
assert(G.db.factionFarming==false,"The opt-out must survive reload")
assert(G.SourceStatus(rfc,G.byID[2585],ally,G.db))
assert(G.SourceStatus(rol,G.byID[2585],horde,G.db))
G.quests[999998].faction="Alliance"
assert(not G.SourceStatus(dq,G.byID[2585],horde,G.db),"The preference cannot bypass an actual quest faction restriction")
G.db.factionFarming=true
G.quests[999998]=nil; G.db.uncertain=false
UnitFactionGroup=function() return "Horde","Localized Horde" end
assert(G.Character().faction=="Horde","Use the stable faction token")
UnitFactionGroup=function() return "Alliance" end
local synthetic={id=999,name="test",level=1,slot=13,classID=2,sub=15,stats={[3]=10,[38]=5},armor=0,damage={10,30,2000},sources={craft},effects={},ilvl=10,quality=2,flags=0,bind=2}
synthetic.bind=1; assert(not G.SourceStatus(craft,synthetic,c,G.db),"Cannot commission a soulbound craft")
synthetic.bind=4; assert(not G.SourceStatus(craft,synthetic,c,G.db),"Quest-bound items are not tradable commissions")
synthetic.bind=2
assert(G.Score(synthetic,{[3]=2,[38]=1,meleeDPS=7})==95,"Independent expected score")
assert(#G.TargetSlots(synthetic,char("ROGUE",9),G.profiles["ROGUE:Combat"],G.db)==1)
assert(#G.TargetSlots(synthetic,char("ROGUE",10),G.profiles["ROGUE:Combat"],G.db)==2)
assert(#G.TargetSlots(synthetic,char("WARRIOR",25),G.profiles["WARRIOR:Arms"],G.db)==0)
local old=synthetic.slot; synthetic.slot=17
assert(#G.TargetSlots(synthetic,char("WARRIOR",25),G.profiles["WARRIOR:Protection"],G.db)==0)
synthetic.slot=old
G.db.weights["MAGE:Frost"]={[5]=7}; assert(G.Weights(G.profiles["MAGE:Frost"])[5]==7)
assert(G.Weights(G.profiles["MAGE:Fire"])[5]==1,"Overrides do not mutate other profiles")
G.db.weights={}
-- Deterministic ties, no duplicate items within one slot, and the best score first.
local allItems=G.items
local a,b,d,e={},{},{},{}
for k,v in pairs(synthetic) do a[k]=v;b[k]=v;d[k]=v;e[k]=v end
a.id=901;b.id=902;d.id=903;e.id=904;a.slot=1;b.slot=1;d.slot=1;e.slot=1
a.classID=4;b.classID=4;d.classID=4;e.classID=4;a.sub=1;b.sub=1;d.sub=1;e.sub=1
a.stats={[5]=1};b.stats={[5]=8};d.stats={[5]=8};e.stats={[5]=3};a.damage=nil;b.damage=nil;d.damage=nil;e.damage=nil
G.items={a,d,b,e}
local result=G.Rank(c,G.db,G.profiles["MAGE:Frost"])
assert(#result.slots[1]==3 and result.slots[1][1].item.id==902 and result.slots[1][2].item.id==903 and result.slots[1][3].item.id==904)
local fifth,sixth={},{}
for k,v in pairs(a) do fifth[k]=v; sixth[k]=v end
fifth.id=905; fifth.stats={[5]=0.5}; sixth.id=906; sixth.stats={[5]=0.25}
G.items={sixth,a,d,fifth,b,e}; G.db.resultCount=5
local expanded=G.Rank(c,G.db,G.profiles["MAGE:Frost"])
assert(expanded.count==5 and #expanded.slots[1]==5)
for i,id in ipairs({902,903,904,901,905}) do assert(expanded.slots[1][i].item.id==id,"Expanded ranking preserves order and caps at five") end
G.items={a,b}; assert(#G.Rank(c,G.db,G.profiles["MAGE:Frost"]).slots[1]==2,"Do not invent extra matches")
G.db.resultCount=3
G.items={a}; a.sources={rfc}
assert(G.Rank(ally,G.db,G.profiles["MAGE:Frost"]).eligible==0)
a.sources={rfc,craft}
local alternate=G.Rank(ally,G.db,G.profiles["MAGE:Frost"])
assert(alternate.eligible==1 and #alternate.slots[1][1].sources==1 and alternate.slots[1][1].sources[1].source.kind=="craft","Keep an accessible crafting alternative for the same item")
G.items=allItems
-- Every supported class and role can scan the real snapshot.
for _,id in ipairs(G.profileOrder) do
    local p=G.profiles[id]; local player=char(p.class,25)
    local r=G.Rank(player,G.db,p)
    assert(r.eligible>0,"No candidates for "..id)
    for slot,list in pairs(r.slots) do
        assert(#list<=3)
        local previous=math.huge; local seen={}
        for _,candidate in ipairs(list) do
            assert(candidate.item.level<=25 and #candidate.sources>0 and candidate.score<=previous)
            assert(not seen[candidate.item.id]); seen[candidate.item.id]=true; previous=candidate.score
        end
    end
end
-- Profession scans must not learn a guild member's or linked recipe list.
C_TradeSkillUI={GetAllRecipeIDs=function() return {2403,12067} end,GetRecipeInfo=function(id) return {learned=id==2403} end}
G.ScanRecipes(); assert(G.db.known[2403] and not G.db.known[12067])
G.db.known={}; C_TradeSkillUI.IsTradeSkillLinked=function() return true end
G.ScanRecipes(); assert(not next(G.db.known)); C_TradeSkillUI=nil
-- Party links are drafts. A live item link is required, and other drafts survive.
local chat={text="",channel="SAY",cursor=0}
function chat:GetText() return self.text end
function chat:GetChatType() return self.channel end
function chat:SetChatType(channel) self.channel=channel end
function chat:GetAttribute() return self.channel end
function chat:SetAttribute(_,channel) self.channel=channel end
function chat:UpdateHeader() self.header=self.channel end
function chat:HighlightText() self.highlightCleared=true end
function chat:SetCursorPosition(position) self.cursor=position end
function chat:SetFocus() self.focused=true end
function chat:Insert(value) self.text=self.text:sub(1,self.cursor)..value..self.text:sub(self.cursor+1); self.cursor=self.cursor+#value end
local chatActive,activated,sent,requested=nil,0,0,nil
LE_PARTY_CATEGORY_HOME,LE_PARTY_CATEGORY_INSTANCE=1,2
local group="none"
IsInGroup=function(category) return group=="home" and category==1 or group=="instance" and category==2 end
local loaded=true
local function link(id) return "|cff1eff00|Hitem:"..id..":0:0:0|h[Test item]|h|r" end
C_Item={GetItemInfo=function(id) if loaded then return "Test item",link(id) end end,RequestLoadItemDataByID=function(id) requested=id end}
SendChatMessage=function() sent=sent+1 end
C_ChatInfo={SendChatMessage=function() sent=sent+1 end}
ChatFrameUtil={GetActiveWindow=function() return chatActive end,ChooseBoxForSend=function() return chat end,
    ActivateChat=function(editor) activated=activated+1; chatActive=editor end}
assert(not G.LinkToParty(nil) and not G.LinkToParty(G.byID[2585]) and activated==0)
group="home"; loaded=false
assert(not G.LinkToParty(G.byID[2585]) and requested==2585 and activated==0)
loaded=true
assert(G.LinkToParty(G.byID[2585]) and chat.channel=="PARTY" and chat.header=="PARTY" and chat.text==link(2585) and sent==0)
chat.text="Could we farm this?"; chat.cursor=0
assert(G.LinkToParty(G.byID[2585]) and chat.text=="Could we farm this? "..link(2585) and chat.highlightCleared,"Preserve the party draft and append the link")
chat.text="Private draft"; chat.channel="WHISPER"; local before=activated
assert(not G.LinkToParty(G.byID[2585]) and chat.text=="Private draft" and chat.channel=="WHISPER" and activated==before)
chat.text="/w Friend private"; chat.channel="PARTY"
assert(not G.LinkToParty(G.byID[2585]) and chat.text=="/w Friend private","Do not append to an unfinished slash command")
chat.text=""; chat.cursor=0; group="instance"
assert(G.LinkToParty(G.byID[2585]) and chat.channel=="INSTANCE_CHAT" and sent==0)
-- Older clients use the global chat helpers and the chatType attribute.
ChatEdit_GetActiveWindow=ChatFrameUtil.GetActiveWindow
ChatEdit_ChooseBoxForSend=ChatFrameUtil.ChooseBoxForSend
ChatEdit_ActivateChat=ChatFrameUtil.ActivateChat
ChatEdit_UpdateHeader=function(editor) editor.header=editor.channel end
ChatFrameUtil=nil; chat.SetChatType=nil; chat.GetChatType=nil; chat.UpdateHeader=nil
chat.text=""; chat.cursor=0; group="home"
GetItemInfo=C_Item.GetItemInfo; C_Item=nil
assert(G.LinkToParty(G.byID[2585]) and chat.channel=="PARTY" and chat.header=="PARTY" and sent==0)
-- Leave a valid legacy chat mock for the UI shortcut test below.
-- UI creation, scan button scheduling, every result detail, dropdowns and weights.
SlashCmdList.GEARFINDER(""); assert(G.frame:IsShown())
assert(G.status:GetText()=="Choose a role and click Scan.")
assert(not G.partyLink.enabled)
assert(G.ScanLevel()==25 and G.scanLevel==nil and G.levelInput:GetText()=="25")
G.levelDown.scripts.OnClick(); flush()
assert(G.results.character.level==24 and G.results.character.currentLevel==25)
G.levelUp.scripts.OnClick(); flush()
assert(G.results.character.level==25 and G.scanLevel==25)
G.levelInput:SetText("15"); G.levelInput.scripts.OnEnterPressed(G.levelInput); flush()
assert(G.results.character.level==15 and not G.CanEquip(G.byID[2585],G.results.character,G.db))
assert(G.heading:GetText():find("Planning level 15",1,true))
G.levelInput:SetText("30"); G.levelInput.scripts.OnEditFocusLost(G.levelInput); flush()
assert(G.results.character.level==30 and G.CanEquip(G.byID[2585],G.results.character,G.db))
for _,value in ipairs({"invalid","0","61","25.5","1e309"}) do
    G.levelInput:SetText(value); assert(not G.CommitLevelInput()); assert(G.ScanLevel()==30)
end
G.levelInput:SetText("40"); G.levelInput.scripts.OnEscapePressed(G.levelInput)
assert(G.ScanLevel()==30 and G.levelInput:GetText()=="30","Escape cancels an unfinished edit")
assert(G.SetScanLevel(1)); flush(); assert(not G.levelDown.enabled and G.levelUp.enabled)
assert(G.SetScanLevel(60)); flush(); assert(G.levelDown.enabled and not G.levelUp.enabled)
G.SetScanLevel(20); flush()
for _,frame in ipairs(frames) do
    if frame.events.PLAYER_LEVEL_UP then frame.scripts.OnEvent(frame,"PLAYER_LEVEL_UP",26) end
end
assert(G.ScanLevel()==20 and G.levelInput:GetText()=="20","Manual level stays fixed after leveling")
G.levelCurrent.scripts.OnClick(); flush()
assert(G.scanLevel==nil and G.results.character.level==26 and G.levelInput:GetText()=="26")
for _,frame in ipairs(frames) do
    if frame.events.PLAYER_LEVEL_UP then frame.scripts.OnEvent(frame,"PLAYER_LEVEL_UP",27) end
end
assert(G.ScanLevel()==27 and G.levelInput:GetText()=="27","Current mode follows level gains")
G.Scan(); flush(); assert(G.results.character.level==27)
G.SetScanLevel(40); flush(); G.levelInput:SetText(""); G.CommitLevelInput(); flush()
assert(G.scanLevel==nil and G.ScanLevel()==27,"Empty input restores current mode")
-- Planning changes level only. It must not grant future profession skill or recipes.
GetProfessions=function() return 1 end
GetProfessionInfo=function() return "Tailoring",nil,80,nil,nil,nil,197 end
G.db.known[2403]=true
G.SetScanLevel(40); flush()
assert(G.results.character.currentLevel==27 and G.results.character.skills[197]==80 and G.results.character.known[2403])
assert(not G.CanEquip(G.byID[10502],G.results.character,G.db),"Planning does not grant Engineering")
GetProfessions=nil; GetProfessionInfo=nil; G.playerLevel=nil
G.levelCurrent.scripts.OnClick(); flush()
G.Scan(); assert(G.scanning); G.Scan(); assert(#timers==1,"Do not launch overlapping scans")
flush(); assert(not G.scanning and G.results.eligible>0)
assert(#G.rows==68 and G.listBody.h>2000)
for _,row in ipairs(G.rows) do if row.candidate then row.scripts.OnClick(row); assert(G.selected==row.candidate); assert(#G.detailText:GetText()>40) end end
assert(G.partyLink.enabled and G.heading:GetText():find("Alliance",1,true))
chat.text=""; chat.cursor=0
G.partyLink.scripts.OnClick(); assert(chat.text==link(G.selected.item.id) and sent==0)
IsShiftKeyDown=function() return true end
for _,row in ipairs(G.rows) do
    if row.candidate then
        chat.text=""; chat.cursor=0; row.scripts.OnClick(row)
        assert(chat.text==link(row.candidate.item.id) and sent==0); break
    end
end
IsShiftKeyDown=nil; GetItemInfo=nil; IsInGroup=nil
ChatEdit_GetActiveWindow=nil; ChatEdit_ChooseBoxForSend=nil; ChatEdit_ActivateChat=nil; ChatEdit_UpdateHeader=nil
local initialCount=#frames
G.Scan(); flush(); assert(#frames==initialCount,"Rescan must reuse list rows")
assert(not G.partyLink.enabled,"A rescan clears the selected party link")
local originalHeight=G.listBody.h
local firstHeader=G.headers[1]
local firstRow=G.itemRows[1][1]
G.countButton.scripts.OnClick(G.countButton); assert(G.countButton.menu:IsShown())
G.countButton.menu.buttons[2].scripts.OnClick(); flush()
assert(G.db.resultCount==5 and G.results.count==5 and not G.countButton.menu:IsShown())
assert(#G.rows==102 and G.listBody.h>originalHeight and G.headers[1]==firstHeader and G.itemRows[1][1]==firstRow)
local extraCandidate=false
for _,slot in ipairs(G.slots) do
    local row=G.itemRows[slot[1]][5]
    assert(row:IsShown() and row.kind=="Button" and G.headers[slot[1]].kind=="Frame")
    if row.candidate then row.scripts.OnClick(row); assert(G.selected==row.candidate); extraCandidate=true end
end
assert(extraCandidate,"The fifth result can be selected for details")
local expandedFrameCount=#frames
G.countButton.menu.buttons[1].scripts.OnClick(); flush()
assert(G.results.count==3 and G.listBody.h==originalHeight)
for _,slot in ipairs(G.slots) do
    assert(not G.itemRows[slot[1]][4]:IsShown() and not G.itemRows[slot[1]][5]:IsShown())
    assert(#G.results.slots[slot[1]]<=3 and G.headers[slot[1]]:IsShown())
end
G.countButton.menu.buttons[2].scripts.OnClick(); flush()
assert(#frames==expandedFrameCount,"Repeated expansion reuses frames")
G.countButton.menu.buttons[1].scripts.OnClick(); flush()
G.armorButton.scripts.OnClick(G.armorButton); assert(G.armorButton.menu:IsShown())
G.armorButton.menu.buttons[5].scripts.OnClick(); flush()
assert(G.db.armor=="plate" and not G.armorButton.menu:IsShown())
for _,slot in ipairs({1,3,5,6,7,8,9,10}) do assert(#G.results.slots[slot]==0,"Mage cannot gain plate results through a filter") end
assert(G.results.eligible>0,"Other equipment still has candidates")
G.armorButton.menu.buttons[2].scripts.OnClick(); flush()
assert(G.db.armor=="cloth" and #G.results.slots[5]>0,"Cloth choice restores mage armor results")
G.armorButton.menu.buttons[1].scripts.OnClick(); flush(); assert(G.db.armor=="all")
G.profileButton.scripts.OnClick(G.profileButton); assert(G.profileButton.menu:IsShown())
G.profileButton.menu.buttons[2].scripts.OnClick(); flush(); assert(G.db.profile=="MAGE:Fire")
for _,f in ipairs(frames) do if f.text=="Edit stat weights" then f.scripts.OnClick(f); break end end
assert(G.weightsFrame and G.weightsFrame:IsShown())
G.factionFarmingCheck:SetChecked(false); G.factionFarmingCheck.scripts.OnClick(G.factionFarmingCheck); flush()
assert(G.db.factionFarming==false and G.DungeonAllowed("ruins-of-lordaeron","Horde"))
G.factionFarmingCheck:SetChecked(true); G.factionFarmingCheck.scripts.OnClick(G.factionFarmingCheck); flush()
assert(G.db.factionFarming==true and not G.DungeonAllowed("ruins-of-lordaeron","Horde"))
for _,f in ipairs(frames) do if f.parent==G.weightsFrame and f.text=="Save" then f.scripts.OnClick(f); break end end
flush(); assert(G.db.weights["MAGE:Fire"])
G.Tooltip(G.frame,G.byID[2585]); assert(G.hover and GameTooltip.link=="item:2585")
G.HideTooltip(); assert(not G.hover)
SlashCmdList.GEARFINDER(""); assert(not G.frame:IsShown())
SlashCmdList.GEARFINDER("resetpos"); assert(G.frame:IsShown())
-- A new character cannot inherit a role for the wrong class.
UnitClass=function() return "Druid","DRUID",11 end
G.Initialize(); assert(G.db.profile=="DRUID:Feral cat")
-- Source lookup works without a ranking scan and does not hide excluded routes.
assert(G.ParseItemID("5191")==5191 and G.ParseItemID("item:5191:0:0")==5191)
assert(not G.ParseItemID("spell:5191") and not G.ParseItemID("0") and not G.ParseItemID(-1))
local exactLink="|cff1eff00|Hitem:5191:17:0:0:0:0:99:123:25|h[Cruel Barb]|h|r"
assert(G.ParseItemID(exactLink)==5191 and G.LookupItem(exactLink).link==exactLink)
local savedResults=G.results; G.results=nil
G.db.dungeon=false; G.db.quest=false; G.db.craft=false; G.db.classic=false
G.ShowSources(); assert(G.sourceFrame:IsShown() and not G.sourceParty.enabled)
assert(G.ShowItemSource(exactLink) and G.sourceItem.id==5191 and G.sourceParty.enabled)
assert(G.sourceText:GetText():find("Classic",1,true) and G.sourceText:GetText():find("Cruel Barb",1,true))
assert(G.sourceText:GetText():find("actual source is not known",1,true))
assert(not G.ShowItemSource("bad input") and G.sourceItem.id==5191)
assert(G.ShowItemSource(2000000000) and G.sourceText:GetText():find("No acquisition source",1,true))
G.sourceInput:SetText("2585"); G.sourceLookup.scripts.OnClick()
assert(G.sourceItem.id==2585 and G.sourceText:GetText():find("Recipe spell ID",1,true))
local questItem
for _,item in ipairs(G.items) do
    for _,source in ipairs(item.sources) do if source.kind=="quest" then questItem=item; break end end
    if questItem then break end
end
assert(G.ShowItemSource(questItem.id) and G.sourceQuest.enabled and G.sourceQuestID)
G.sourceQuest.scripts.OnClick(); assert(G.sourceURL:GetText():find("quest=",1,true))
SlashCmdList.GEARFINDER("item "..exactLink); assert(G.sourceItem.link==exactLink)
G.db.dungeon=true; G.db.quest=true; G.db.craft=true; G.db.classic=true; G.results=savedResults
-- Only the matching inspect response may populate the list, with no stale target data.
local targetGUID,playerTarget,canInspect,combat,clockValue="Player-A",true,true,false,100
local notified,cleared=0,0
UnitGUID=function() return targetGUID end
UnitIsPlayer=function() return playerTarget end
UnitIsUnit=function(a,b) return a==b end
CanInspect=function() return canInspect end
InCombatLockdown=function() return combat end
GetTime=function() return clockValue end
NotifyInspect=function(unit) assert(unit=="target"); notified=notified+1 end
ClearInspectPlayer=function() cleared=cleared+1 end
GetInventoryItemLink=function(unit,slot) if unit=="target" and slot==16 then return exactLink end end
local function fire(event,value)
    for _,frame in ipairs(frames) do if frame.events[event] then frame.scripts.OnEvent(frame,event,value) end end
end
assert(G.InspectTarget() and G.inspectPending and notified==1)
assert(not G.InspectTarget() and notified==1,"Do not flood inspection requests")
fire("INSPECT_READY","Player-B"); assert(G.inspectPending and #G.inspectedGear==0)
fire("INSPECT_READY","Player-A"); assert(not G.inspectPending and #G.inspectedGear==#G.slots)
local inspectedRow
for _,row in ipairs(G.inspectRows) do if row.entry.slot==16 then inspectedRow=row end end
assert(inspectedRow.entry.item.link==exactLink and inspectedRow.enabled)
inspectedRow.scripts.OnClick(inspectedRow); assert(G.sourceItem.link==exactLink)
flush(); assert(not G.inspectStatus:GetText():find("timed out",1,true),"Late timeout cannot erase successful inspection")
assert(not G.InspectTarget() and notified==1,"Throttle completed inspections too")
clockValue=104; assert(G.InspectTarget()); targetGUID="Player-B"
fire("INSPECT_READY","Player-A"); assert(not G.inspectPending and #G.inspectedGear==0)
clockValue=108; assert(G.InspectTarget()); fire("PLAYER_TARGET_CHANGED"); assert(not G.inspectPending)
fire("INSPECT_READY","Player-B"); assert(#G.inspectedGear==0)
clockValue=112; assert(G.InspectTarget()); flush(); assert(not G.inspectPending and G.inspectStatus:GetText():find("timed out",1,true))
clockValue=116; assert(G.InspectTarget()); G.sourceFrame:Hide(); assert(not G.inspectPending)
fire("INSPECT_READY","Player-B"); assert(#G.inspectedGear==0 and cleared==0)
playerTarget=false; assert(not G.InspectTarget()); playerTarget=true
canInspect=false; assert(not G.InspectTarget()); canInspect=true
combat=true; assert(not G.InspectTarget()); combat=false
InspectFrame={unit="party1",IsShown=function() return true end}; assert(not G.InspectTarget()); InspectFrame=nil
clockValue=120; NotifyInspect=function() error("Unavailable") end
assert(not G.InspectTarget() and not G.inspectPending)
-- A failed item-data load must not create an endless request loop.
local sourceRequests=0
C_Item={RequestLoadItemDataByID=function() sourceRequests=sourceRequests+1 end}
G.ShowItemSource(1999999999); fire("ITEM_DATA_LOAD_RESULT",1999999999); fire("ITEM_DATA_LOAD_RESULT",1999999999)
assert(sourceRequests==1 and G.sourceItem.id==1999999999)
C_Item.GetItemInfo=function(id) return "Loaded item",link(id) end
fire("ITEM_DATA_LOAD_RESULT",1999999999); assert(G.sourceItem.name=="Loaded item")
-- Party drafts preserve the exact inspected item variant even if uncached.
C_Item=nil; GetItemInfo=nil
IsInGroup=function(category) return category==LE_PARTY_CATEGORY_HOME end
chat.text=""; chat.cursor=0; chat.channel="PARTY"
ChatEdit_GetActiveWindow=function() return chat end
ChatEdit_ActivateChat=function() end
assert(G.LinkToParty({id=5191,link=exactLink}) and chat.text==exactLink and sent==0)
-- Native Inspect is load-on-demand. Attach once and preserve its click handler.
local nativeClicks,hooks=0,0
InspectFrame=CreateFrame("Frame","InspectFrame"); InspectFrame.unit="party1"
InspectPaperDollFrame=CreateFrame("Frame","InspectPaperDollFrame",InspectFrame)
InspectPaperDollItemSlotButton_OnClick=function() nativeClicks=nativeClicks+1 end
hooksecurefunc=function(name,hook)
    hooks=hooks+1
    local original=_G[name]
    _G[name]=function(...) original(...); hook(...) end
end
UnitGUID=function(unit) return unit=="party1" and "Inspected-player" or "Different-target" end
GetInventoryItemLink=function(unit,slot)
    assert(unit=="party1","Read the inspected player, not the current target")
    if slot==16 then return exactLink elseif slot==5 then return link(2585) end
end
GetInventoryItemID=function() return nil end
-- XML stores the function on each button before the add-on attaches.
local nativeSlot=CreateFrame("Button","InspectMainHandSlot"); nativeSlot.id=16
nativeSlot:SetScript("OnClick",InspectPaperDollItemSlotButton_OnClick)
INSPECTPAPERDOLLFRAME_SLOTS={"InspectMainHandSlot"}
local oldRequests=notified
fire("ADDON_LOADED","Blizzard_InspectUI")
assert(G.nativeSourceButton and hooks==0 and not G.nativeSourcePanel:IsShown())
fire("ADDON_LOADED","UnrelatedAddon"); G.AttachNativeInspect(); assert(hooks==0)
assert(nativeSlot.hookCounts.OnClick==1,"Repeated attachment must not duplicate button hooks")

nativeSlot.scripts.OnClick(nativeSlot,"LeftButton"); assert(nativeClicks==1 and not G.nativeSourcePanel:IsShown())
G.nativeSourceButton.scripts.OnClick(); assert(G.nativeLookupGUID=="Inspected-player" and G.nativeSourcePanel:IsShown())
IsModifiedClick=function() return true end
nativeSlot.scripts.OnClick(nativeSlot,"LeftButton")
IsModifiedClick=nil
assert(nativeClicks==2 and G.nativeSourceItem.link==exactLink and G.nativeSourceText:GetText():find("Cruel Barb",1,true))
nativeSlot.id=5; nativeSlot.scripts.OnClick(nativeSlot,"LeftButton")
assert(G.nativeSourceItem.id==2585 and G.nativeSourceText:GetText():find("Recipe spell ID",1,true))
nativeSlot.id=16; IsShiftKeyDown=function() return true end
nativeSlot.scripts.OnClick(nativeSlot,"LeftButton"); assert(G.nativeSourceItem.id==2585 and nativeClicks==4)
IsShiftKeyDown=nil
nativeSlot.scripts.OnClick(nativeSlot,"RightButton"); assert(G.nativeSourceItem.id==2585 and nativeClicks==5)
nativeSlot.id=1; nativeSlot.scripts.OnClick(nativeSlot,"LeftButton")
assert(not G.nativeSourceItem and not G.nativeSourceParty.enabled and G.nativeSourceURL:GetText()=="")
nativeSlot.id=16; nativeSlot.scripts.OnClick(nativeSlot,"LeftButton")
G.nativeSourcePage.scripts.OnClick(); assert(G.nativeSourceURL:GetText():find("id=5191",1,true))
chat.text=""; chat.cursor=0; G.nativeSourceParty.scripts.OnClick(); assert(chat.text==exactLink and sent==0)
G.nativeSourceButton.scripts.OnClick(); assert(not G.nativeLookupGUID and not G.nativeSourcePanel:IsShown())
G.nativeSourceButton.scripts.OnClick(); InspectFrame:Hide()
assert(not G.nativeLookupGUID and not G.nativeSourcePanel:IsShown())
InspectFrame:Show(); G.nativeSourceButton.scripts.OnClick(); fire("PLAYER_TARGET_CHANGED")
assert(not G.nativeLookupGUID and G.nativeSourceButton:GetText()=="Find sources")
G.nativeSourceButton.scripts.OnClick(); InspectFrame.unit="party2"
nativeSlot.scripts.OnClick(nativeSlot,"LeftButton"); assert(not G.nativeLookupGUID)
assert(notified==oldRequests,"Native source lookup must reuse inspect data without extra server requests")
-- Slot frames created after the Inspect add-on loads are attached on demand.
local lateSlot=CreateFrame("Button","InspectRangedSlot"); lateSlot.id=16
lateSlot:SetScript("OnClick",InspectPaperDollItemSlotButton_OnClick)
local arraySlot=CreateFrame("Button"); arraySlot.id=5
arraySlot:SetScript("OnClick",InspectPaperDollItemSlotButton_OnClick)
InspectPaperDollItemsFrame={WeaponSlots={arraySlot}}
InspectFrame.unit="party1"; G.nativeSourceButton.scripts.OnClick()
lateSlot.scripts.OnClick(lateSlot,"LeftButton"); assert(G.nativeSourceItem.id==5191)
arraySlot.scripts.OnClick(arraySlot,"LeftButton"); assert(G.nativeSourceItem.id==2585)
G.HookNativeInspectSlots(); assert(lateSlot.hookCounts.OnClick==1 and arraySlot.hookCounts.OnClick==1)
-- Reserve space for native side tabs and keep the panel inside the screen.
for _,case in ipairs({
    {815,610,8,338,600,388},
    {1920,1080,10,350,1060,410},
    {1000,700,640,980,690,1000},
    {800,430,10,350,425,410},
}) do
    local width,height,left,right,top,rail=unpack(case)
    local x,y,scale=G.NativeSourcePlacement(width,height,left,right,top,rail)
    assert(x>=0 and x+400*scale<=width and y<=height and y-573*scale>=0,"Panel stays within the screen")
    assert(x>=rail+12 or x+400*scale<=left-12,"Panel cannot overlap the inspect window or its side tabs")
end
-- The tab buttons can extend farther than their container.
UIParent.w=1000; UIParent.h=700
InspectFrame.GetLeft=function() return 10 end
InspectFrame.GetRight=function() return 350 end
InspectFrame.GetTop=function() return 690 end
InspectFrame.GetEffectiveScale=function() return 1 end
InspectPaperDollFrame.GetEffectiveScale=function() return 1 end
InspectFrame.ModeTabs={GetRight=function() return 380 end,GetEffectiveScale=function() return 1 end,
    Tabs={{IsShown=function() return true end,GetRight=function() return 425 end,GetEffectiveScale=function() return 1 end}}}
G.LayoutNativeSources()
assert(G.nativeSourcePanel.point[4]==437,"Dock beyond the outer edge of visible tab buttons")
assert(G.nativeSourceText.w < G.nativeSourceScroll.w and G.nativeSourceScroll.h==340)
G.nativeSourceBody:SetHeight(800)
G.nativeSourceScroll.GetVerticalScroll=function(self) return self.scroll end
G.nativeSourceScroll:SetVerticalScroll(0)
G.nativeSourceScroll.scripts.OnMouseWheel(G.nativeSourceScroll,-1); assert(G.nativeSourceScroll.scroll==40)
G.nativeSourceScroll.scripts.OnMouseWheel(G.nativeSourceScroll,-100); assert(G.nativeSourceScroll.scroll==460)
G.nativeSourceScroll.scripts.OnMouseWheel(G.nativeSourceScroll,100); assert(G.nativeSourceScroll.scroll==0)


