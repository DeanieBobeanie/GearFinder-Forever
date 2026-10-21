local _, G = ...
local safe=G.Safe
local function label(parent,x,y,width,value)
    local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); t:SetWordWrap(true); t:SetText(value or "")
    return t
end
local function button(parent,x,y,width,value,action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y); b:SetSize(width,25); b:SetText(value); b:SetScript("OnClick",action)
    return b
end
local function copyURL(value)
    G.sourceURL:SetText(value); G.sourceURL:SetFocus(); G.sourceURL:HighlightText()
end
function G.ShowItemSource(value)
    local item=value and G.LookupItem(value)
    if value and not item then G.inspectStatus:SetText("Enter an item ID or item link, or use /gear item followed by a linked item."); return false end
    G.sourceItem=item
    G.sourceParty:SetEnabled(item~=nil); G.sourcePage:SetEnabled(item~=nil)
    local quest
    for _,source in ipairs(item and item.record and item.record.sources or {}) do if source.quest then quest=source.quest; break end end
    G.sourceQuestID=quest; G.sourceQuest:SetEnabled(quest~=nil)
    G.sourceText:SetText(item and G.LookupText(item) or "Select an equipped item, or look up an item ID or link.\n\nTo use a chat link, type /gear item followed by a space in chat, Shift-click the item link, then press Enter.")
    G.sourceBody:SetHeight(math.max(385,G.sourceText:GetStringHeight()+20)); G.sourceScroll:SetVerticalScroll(0)
    G.sourceURL:SetText(item and "https://forever-codex.com/items/?id="..item.id or "")
    return item~=nil
end
function G.RenderInspectedGear()
    if not G.inspectRows then return end
    for i,row in ipairs(G.inspectRows) do
        local entry=G.inspectedGear and G.inspectedGear[i]
        row.entry=entry
        row:SetText(entry and entry.label..": "..(entry.item and entry.item.name or "Empty / unavailable") or G.slots[i][2]..": No inspection")
        row:SetEnabled(entry and entry.item~=nil or false)
    end
end
function G.ShowSources()
    if G.sourceFrame then G.sourceFrame:Show(); return end
    local f=CreateFrame("Frame","GearFinderSourcesFrame",UIParent,"BackdropTemplate"); G.sourceFrame=f
    f:SetSize(900,640); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true)
    local scale=math.min(1,(UIParent:GetWidth()-40)/900,(UIParent:GetHeight()-40)/640); f:SetScale(scale)
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.045,0.05,0.065,0.98)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",function(self) self:StartMovingOrSizing() end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f:SetScript("OnHide",function() G.CancelInspect(); if GameTooltip then GameTooltip:Hide() end end)
    UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="GearFinderSourcesFrame"
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5); close:SetScript("OnClick",function() f:Hide() end)
    label(f,16,-16,800,"Gear Finder / Inspect and item sources")
    G.inspectTargetButton=button(f,16,-48,150,"Inspect target",G.InspectTarget)
    button(f,176,-48,110,"My gear",function()
        G.CancelInspect(); G.ReadInspectedGear("player"); G.ShowItemSource(nil); G.inspectStatus:SetText("Your equipped gear. Click an item for sources.")
    end)
    label(f,320,-30,450,"Item ID or pasted item link")
    G.sourceInput=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); G.sourceInput:SetPoint("TOPLEFT",326,-50); G.sourceInput:SetSize(390,24); G.sourceInput:SetAutoFocus(false)
    local lookup=function() if G.ShowItemSource(G.sourceInput:GetText()) then G.sourceInput:ClearFocus() end end
    G.sourceInput:SetScript("OnEnterPressed",lookup)
    G.sourceInput:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    G.sourceInput:SetScript("OnReceiveDrag",function(self)
        local kind,id,link=safe(GetCursorInfo)
        if kind=="item" and G.ParseItemID(link or id) then self:SetText(link or tostring(id)); lookup(); safe(ClearCursor) end
    end)
    G.sourceLookup=button(f,736,-48,140,"Find sources",lookup)
    G.inspectStatus=label(f,16,-88,860,"Target a nearby player, then click Inspect target. You can also look up an item without inspecting anyone.")
    local list=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); list:SetPoint("TOPLEFT",16,-130); list:SetSize(290,455)
    local body=CreateFrame("Frame",nil,list); body:SetSize(286,#G.slots*31); list:SetScrollChild(body)
    G.inspectRows={}
    for i in ipairs(G.slots) do
        local row=button(body,0,-(i-1)*31,282,"",function(self)
            if self.entry and self.entry.item then
                local item=self.entry.item; G.ShowItemSource(item.link or item.id)
                if safe(IsModifiedClick,"CHATLINK") or safe(IsShiftKeyDown) then G.LinkToParty(item) end
            end
        end)
        local rowText=safe(row.GetFontString,row)
        if rowText then rowText:SetWidth(268); safe(rowText.SetMaxLines,rowText,1) end
        row:SetScript("OnEnter",function(self)
            local item=self.entry and self.entry.item
            if item and GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); safe(GameTooltip.SetHyperlink,GameTooltip,item.link or "item:"..item.id); GameTooltip:Show() end
        end)
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        G.inspectRows[i]=row
    end
    G.sourceScroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); G.sourceScroll:SetPoint("TOPLEFT",350,-130); G.sourceScroll:SetSize(500,385)
    G.sourceBody=CreateFrame("Frame",nil,G.sourceScroll); G.sourceBody:SetSize(495,385); G.sourceScroll:SetScrollChild(G.sourceBody)
    G.sourceText=label(G.sourceBody,0,0,490,"")
    G.sourceParty=button(f,346,-532,160,"Link to party",function() G.LinkToParty(G.sourceItem) end)
    G.sourcePage=button(f,516,-532,155,"Item page",function() if G.sourceItem then copyURL("https://forever-codex.com/items/?id="..G.sourceItem.id) end end)
    G.sourceQuest=button(f,681,-532,165,"First quest page",function() if G.sourceQuestID then copyURL("https://www.wowhead.com/forever/quest="..G.sourceQuestID) end end)
    G.sourceURL=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); G.sourceURL:SetPoint("TOPLEFT",356,-572); G.sourceURL:SetSize(490,22); G.sourceURL:SetAutoFocus(false)
    G.sourceURL:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    label(f,350,-606,530,"Copy page URLs with Ctrl+C. Party links are drafts. Press Enter to send.")
    G.RenderInspectedGear(); G.ShowItemSource(nil); f:Show()
end
