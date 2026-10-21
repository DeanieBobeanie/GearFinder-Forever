local _, G = ...
local safe = G.Safe

function G.LinkToParty(item)
    if not item then G.Print("Select an item to link to your party."); return false end
    local home = safe(IsInGroup,LE_PARTY_CATEGORY_HOME)
    local instance = LE_PARTY_CATEGORY_INSTANCE and safe(IsInGroup,LE_PARTY_CATEGORY_INSTANCE)
    if home == nil then home = (safe(GetNumPartyMembers) or safe(GetNumSubgroupMembers) or 0) > 0 end
    if not home and not instance then G.Print("Join a party before linking an item."); return false end
    local channel = instance and not home and "INSTANCE_CHAT" or "PARTY"
    local _, link = safe(C_Item and C_Item.GetItemInfo or GetItemInfo,item.id)
    if type(item.link)=="string" and item.link:find("|Hitem:"..item.id.."[:|]") then link=item.link end
    if type(link) ~= "string" or not link:find("|Hitem:"..item.id.."[:|]") then
        safe(C_Item and C_Item.RequestLoadItemDataByID,item.id)
        G.Print("Item data is loading. Hover the item, then click Link to party again.")
        return false
    end
    local api = ChatFrameUtil or {}
    local edit = safe(api.GetActiveWindow or ChatEdit_GetActiveWindow)
        or safe(api.ChooseBoxForSend or ChatEdit_ChooseBoxForSend,DEFAULT_CHAT_FRAME)
        or DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if not edit or type(edit.GetText) ~= "function" or type(edit.Insert) ~= "function" then
        G.Print("Open party chat with /p, then click Link to party again.")
        return false
    end
    local draft = safe(edit.GetText,edit)
    local current = safe(edit.GetChatType,edit) or safe(edit.GetAttribute,edit,"chatType")
    if type(draft) ~= "string" then return false end
    if draft ~= "" and (current ~= channel or draft:match("^%s*/")) then
        G.Print("Finish or clear your existing chat draft before creating a party link.")
        return false
    end
    local activate = api.ActivateChat or ChatEdit_ActivateChat
    if type(activate) ~= "function" or not pcall(activate,edit) then
        G.Print("Could not open party chat. Open /p and try again.")
        return false
    end
    local ok
    if type(edit.SetChatType) == "function" then ok = pcall(edit.SetChatType,edit,channel)
    elseif type(edit.SetAttribute) == "function" then ok = pcall(edit.SetAttribute,edit,"chatType",channel) end
    if not ok then G.Print("This client could not select party chat."); return false end
    if edit.UpdateHeader then safe(edit.UpdateHeader,edit) else safe(ChatEdit_UpdateHeader,edit) end
    -- Append without replacing an existing party draft or a selected range.
    if draft ~= "" then
        safe(edit.HighlightText,edit,0,0)
        safe(edit.SetCursorPosition,edit,#draft)
    end
    local prefix = draft ~= "" and not draft:match("%s$") and " " or ""
    if not pcall(edit.Insert,edit,prefix..link) then
        G.Print("The item link could not be inserted. Try opening /p first.")
        return false
    end
    safe(edit.SetFocus,edit)
    return true
end
