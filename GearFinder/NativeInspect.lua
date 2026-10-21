local _, G = ...
local safe=G.Safe

-- Coordinates are in UIParent units, including the native side-tab rail.
function G.NativeSourcePlacement(width,height,left,right,top,railRight)
    local gap,margin=12,10
    local edge=math.max(right,railRight or right)
    local rightSpace=math.max(1,width-edge-gap-margin)
    local leftSpace=math.max(1,left-gap-margin)
    local useLeft=rightSpace<400 and leftSpace>rightSpace
    local scale=math.min(1,(useLeft and leftSpace or rightSpace)/400,(height-2*margin)/573)
    local x=useLeft and left-gap-400*scale or edge+gap
    local y=math.min(height-margin,math.max(573*scale+margin,top))
    return x,y,scale
end

function G.LayoutNativeSources()
    if not G.nativeSourcePanel then return end
    local uiScale=safe(UIParent.GetEffectiveScale,UIParent) or 1
    local function coordinate(frame,method)
        local value=frame and safe(frame[method],frame)
        return value and value*(safe(frame.GetEffectiveScale,frame) or uiScale)/uiScale
    end
    local left=coordinate(InspectFrame,"GetLeft") or 10
    local right=coordinate(InspectFrame,"GetRight") or left+340
    local top=coordinate(InspectFrame,"GetTop") or UIParent:GetHeight()-10
    local rail=right
    if InspectFrame.ModeTabs then
        rail=math.max(rail,coordinate(InspectFrame.ModeTabs,"GetRight") or right)
        for _,tab in ipairs(InspectFrame.ModeTabs.Tabs or {}) do
            if safe(tab.IsShown,tab) then rail=math.max(rail,coordinate(tab,"GetRight") or right) end
        end
    else rail=right+50 end
    local x,y,scale=G.NativeSourcePlacement(UIParent:GetWidth(),UIParent:GetHeight(),left,right,top,rail)
    local parent=InspectPaperDollFrame or InspectFrame
    local relativeScale=scale*uiScale/(safe(parent.GetEffectiveScale,parent) or uiScale)
    local f,b=G.nativeSourcePanel,G.nativeSourceButton
    f:SetScale(relativeScale); b:SetScale(relativeScale)
    f:ClearAllPoints(); b:ClearAllPoints()
    b:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
    f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale-33)
end

function G.StopNativeLookup()
    G.nativeLookupGUID=nil
    if G.nativeSourceButton then G.nativeSourceButton:SetText("Find sources") end
    if G.nativeSourcePanel then G.nativeSourcePanel:Hide() end
end

local function showItem(value)
    local item=G.LookupItem(value)
    if not item then return end
    G.nativeSourceItem=item
    G.nativeSourceText:SetText(G.LookupText(item))
    G.nativeSourceBody:SetHeight(math.max(340,G.nativeSourceText:GetStringHeight()+20))
    G.nativeSourceScroll:SetVerticalScroll(0)
    G.nativeSourceURL:SetText("https://forever-codex.com/items/?id="..item.id)
    G.nativeSourceParty:SetEnabled(true)
    G.nativeSourcePage:SetEnabled(true)
    G.nativeSourcePanel:Show()
end

function G.NativeInspectItemClicked(slotButton,mouseButton)
    if not G.nativeLookupGUID or mouseButton~="LeftButton" then return end
    if safe(IsShiftKeyDown) or safe(IsControlKeyDown) or safe(IsAltKeyDown) then return end
    local unit=InspectFrame and InspectFrame.unit
    if not unit or not safe(InspectFrame.IsShown,InspectFrame) or safe(UnitGUID,unit)~=G.nativeLookupGUID then
        G.StopNativeLookup(); return
    end
    local slot=safe(slotButton.GetID,slotButton)
    if not slot then return end
    local link=safe(GetInventoryItemLink,unit,slot)
    local id=G.ParseItemID(link) or G.ParseItemID(safe(GetInventoryItemID,unit,slot))
    if not id then
        G.nativeSourceItem=nil
        G.nativeSourceText:SetText("This slot is empty or its item data is not available yet. Try another item, or wait for the inspection to finish.")
        G.nativeSourceBody:SetHeight(340); G.nativeSourceScroll:SetVerticalScroll(0)
        G.nativeSourceURL:SetText(""); G.nativeSourceParty:SetEnabled(false); G.nativeSourcePage:SetEnabled(false)
        G.nativeSourcePanel:Show(); return
    end
    showItem(link or id)
end

function G.HookNativeInspectSlots()
    G.nativeHookedSlots=G.nativeHookedSlots or {}
    local function attach(slot)
        if not slot or not slot.HookScript or G.nativeHookedSlots[slot] then return end
        -- XML keeps a function reference on the button. Hook that script directly.
        slot:HookScript("OnClick",G.NativeInspectItemClicked)
        G.nativeHookedSlots[slot]=true
    end
    for _,name in ipairs(INSPECTPAPERDOLLFRAME_SLOTS or {}) do attach(_G[name]) end
    for _,name in ipairs({"Head","Neck","Shoulder","Back","Chest","Shirt","Tabard","Wrist","Hands","Waist","Legs","Feet","Finger0","Finger1","Trinket0","Trinket1","MainHand","SecondaryHand","Ranged"}) do
        attach(_G["Inspect"..name.."Slot"])
    end
    for _,parent in pairs({InspectPaperDollItemsFrame,InspectPaperDollFrame}) do
        for _,key in ipairs({"LeftEquipmentSlots","RightEquipmentSlots","WeaponSlots"}) do
            for _,slot in ipairs(parent[key] or {}) do attach(slot) end
        end
    end
end

function G.AttachNativeInspect()
    if not InspectFrame or not InspectFrame.HookScript then return end
    G.HookNativeInspectSlots()
    if G.nativeSourceButton then return end
    local parent=InspectPaperDollFrame or InspectFrame
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); G.nativeSourceButton=b
    b:SetSize(160,25); b:SetFrameStrata("DIALOG"); b:SetText("Find sources")
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate"); G.nativeSourcePanel=f
    f:SetSize(400,540); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.045,0.05,0.065,1)
    safe(f.SetBackdrop,f,{edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    safe(f.SetBackdropBorderColor,f,0.55,0.45,0.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetWidth(330); title:SetJustifyH("LEFT"); title:SetText("Item sources")
    local subtitle=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); subtitle:SetPoint("TOPLEFT",16,-42); subtitle:SetWidth(356); subtitle:SetJustifyH("LEFT"); subtitle:SetText("Click another equipped item to compare sources.")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3); close:SetScript("OnClick",G.StopNativeLookup)
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); G.nativeSourceScroll=scroll
    scroll:SetPoint("TOPLEFT",16,-72); scroll:SetSize(350,340)
    local body=CreateFrame("Frame",nil,scroll); G.nativeSourceBody=body; body:SetSize(346,340); scroll:SetScrollChild(body)
    local t=body:CreateFontString(nil,"OVERLAY","GameFontHighlight"); G.nativeSourceText=t
    t:SetPoint("TOPLEFT",0,0); t:SetWidth(342); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); t:SetWordWrap(true); safe(t.SetSpacing,t,3)
    safe(scroll.EnableMouseWheel,scroll,true)
    scroll:SetScript("OnMouseWheel",function(self,delta)
        local current=safe(self.GetVerticalScroll,self) or 0
        local maximum=safe(self.GetVerticalScrollRange,self) or math.max(0,body:GetHeight()-self:GetHeight())
        self:SetVerticalScroll(math.max(0,math.min(maximum,current-delta*40)))
    end)
    local function button(x,label,action)
        local button=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        button:SetSize(178,25); button:SetPoint("TOPLEFT",x,-435); button:SetText(label); button:SetScript("OnClick",action)
        return button
    end
    G.nativeSourceParty=button(14,"Link to party",function() G.LinkToParty(G.nativeSourceItem) end)
    G.nativeSourcePage=button(206,"Copy item page",function()
        if G.nativeSourceItem then G.nativeSourceURL:SetText("https://forever-codex.com/items/?id="..G.nativeSourceItem.id); G.nativeSourceURL:SetFocus(); G.nativeSourceURL:HighlightText() end
    end)
    local url=CreateFrame("EditBox",nil,f,"InputBoxTemplate"); G.nativeSourceURL=url
    url:SetPoint("TOPLEFT",20,-476); url:SetSize(358,22); url:SetAutoFocus(false)
    url:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); hint:SetPoint("TOPLEFT",16,-508); hint:SetWidth(368); hint:SetJustifyH("LEFT"); hint:SetWordWrap(true)
    hint:SetText("Ctrl+C copies the URL. Party links open a draft for you to send.")
    b:SetScript("OnClick",function()
        if G.nativeLookupGUID then G.StopNativeLookup(); return end
        G.HookNativeInspectSlots()
        G.LayoutNativeSources()
        local unit=InspectFrame.unit
        local guid=unit and safe(UnitGUID,unit)
        if not guid then G.Print("Wait for the player's inspection to finish, then try again."); return end
        G.nativeLookupGUID=guid; G.nativeSourceItem=nil
        b:SetText("Click an item")
        G.nativeSourceText:SetText("Click an equipped item in the Inspect window to see its recorded sources.\n\nClick another item to compare sources. Click the button again to finish.")
        body:SetHeight(340); scroll:SetVerticalScroll(0); url:SetText("")
        G.nativeSourceParty:SetEnabled(false); G.nativeSourcePage:SetEnabled(false); f:Show()
    end)
    InspectFrame:HookScript("OnShow",G.HookNativeInspectSlots)
    InspectFrame:HookScript("OnShow",G.LayoutNativeSources)
    InspectFrame:HookScript("OnHide",G.StopNativeLookup)
    if parent~=InspectFrame then parent:HookScript("OnHide",G.StopNativeLookup) end
    G.LayoutNativeSources(); f:Hide()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_TARGET_CHANGED","GROUP_ROSTER_UPDATE","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do safe(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event,id)
    if event=="ADDON_LOADED" or event=="PLAYER_LOGIN" then G.AttachNativeInspect()
    elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then G.LayoutNativeSources()
    elseif event=="PLAYER_TARGET_CHANGED" or event=="GROUP_ROSTER_UPDATE" then G.StopNativeLookup()
    elseif G.nativeLookupGUID and G.nativeSourcePanel:IsShown() and G.nativeSourceItem and G.nativeSourceItem.id==id then
        local item=G.nativeSourceItem; showItem(item.link or item.id)
    end
end)
G.AttachNativeInspect()
