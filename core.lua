local addon_name, addon_data = ...
local uiElements = {}
local count = 0 

function onLoad()
    local frame, events = CreateFrame("Frame"), {};
    -- On addon loaded
    function events:ADDON_LOADED(name)
        if name == addon_name then
            -- Our saved variables are ready at this point. If there are none, both variables will set to nil.
            if BlacklistPlayerList == nil then
                BlacklistPlayerList = {}; -- This is the first time this addon is loaded; initialize the count to 0.
            end
            CreateUI()
        end
    end
    -- Joining a party
    function events:GROUP_ROSTER_UPDATE(...)
        for player, reason in pairs(BlacklistPlayerList) do
            if UnitInParty(player) then
                message(player.." has joined your party and is blacklisted. Reason: "..reason)
            end
        end
    end
    -- Joining a raid
    function events:RAID_ROSTER_UPDATE(...)
        for player, reason in pairs(BlacklistPlayerList) do
            if UnitInRaid(player) then
                message(player.." has joined your raid group and is blacklisted. Reason: "..reason)
            end
        end
    end
    -- Getting an invite to a group
    function events:PARTY_INVITE_REQUEST(...)
        local args = {...}
        local invitedBy = args[1];
        local reason = BlacklistPlayerList[invitedBy];
        if reason ~= nil then
            message(invitedBy.." is inviting you to a group, but is also blacklisted. Reason: "..reason)
        end
    end
    frame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...); -- call one of the functions above
    end);
    for k, v in pairs(events) do
        frame:RegisterEvent(k); -- Register all events for which handlers have been defined
    end
end

function AddToBan (self)
    print(self)
end

local PopUpBan = CreateFrame("Frame","PopUpBanFrame")
PopUpBan:SetScript("OnEvent", function() hooksecurefunc("UnitPopup_OnClick", AddToBan) end)
PopUpBan:RegisterEvent("PLAYER_LOGIN")
local PopupUnits = {}
UnitPopupButtons["BlacklistPlayerPopup"] = { text = "Blacklist", }

for i,UPMenus in pairs(UnitPopupMenus) do
    print(i)
    for j=1, #UPMenus do
        print(UPMenus[j])
        if UPMenus[j] == "INSPECT" then
            PopupUnits[#PopupUnits + 1] = i
            pos = j + 1
            table.insert( UnitPopupMenus[i] ,pos , "BlacklistPlayerPopup" )
            break
        end
    end
end

function CreateUI()
    f = CreateFrame("Frame", "BlacklistFrame", UIParent)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetWidth(300)
    f:SetHeight(500)
    f:SetBackdrop{
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background" ,
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
        tileSize = 32,
        edgeSize = 32,
    }
    f:SetPoint("TOP", 0, -50)
    f:SetScript('OnShow', function() PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or 'igMainMenuOption') end)
    f:SetScript('OnHide', function() PlaySound(SOUNDKIT and SOUNDKIT.GS_TITLE_OPTION_EXIT or 'gsTitleOptionExit') end)

    f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart', function(f) f:StartMoving() end)
    f:SetScript('OnDragStop', function(f) f:StopMovingOrSizing() end)

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Header")
    header:SetWidth(256); header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)

    local title = f:CreateFontString("ARTWORK")
    title:SetFontObject("GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("Blacklist")

	local addButton = CreateFrame("Button", "AddPlayerButton", f, "OptionsButtonTemplate")
    addButton:SetText("Add")
    addButton:SetPoint("TOPRIGHT", -10, -50)
    addButton:SetScript("OnClick", onAddPlayerButtonClicked)

    local removeButton = CreateFrame("Button", "RemovePlayerButton", f, "OptionsButtonTemplate")
    removeButton:SetText("Remove")
    removeButton:SetPoint("TOPRIGHT", -10, -70)
    removeButton:SetScript("OnClick", onRemovePlayerButtonClicked)

    f.editBox = CreateFrame("EditBox", nil, f)
    f.editBox:SetMultiLine(false)
    f.editBox:SetHeight(50)
    f.editBox:SetWidth(200)
    f.editBox:SetPoint("TOP", -15, -15)
    f.editBox:SetMaxLetters(20)
    f.editBox:SetFontObject(GameFontNormal)
    f.editBox:SetScript("OnEscapePressed", function(self)
        hideEditBox(self)
    end)
    f.editBox:SetScript("OnEnterPressed", function(self)
        addPlayer(self:GetText())
        hideEditBox(self)
    end);
    f.editBox:Hide();

    f.list = CreateFrame("ScrollFrame", "PlayerListFrame", f)
    f.list:SetHeight(400)
    f.list:SetWidth(200)
    f.list:SetPoint("TOP", -50, -25)

    renderPlayerList()
    
    tinsert(UISpecialFrames, f:GetName());
    f:Hide()
end

function renderPlayerList()
    uiElements = {}
    for player, reason in pairs(BlacklistPlayerList) do
        createPlayerRow(player, count)
        count = count + 1
    end
end

function createPlayerRow(player, i)
    uiElements[i] = CreateFrame("CheckButton", "BlacklistPlayerRow_"..i, f.list, "OptionsButtonTemplate")
    uiElements[i]:SetText(player)
    uiElements[i]:SetWidth(175)
    uiElements[i]:SetPoint("TOPLEFT", 10, -20 * i - 25)
    uiElements[i]:SetNormalTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    uiElements[i]:SetHighlightTexture("Interface\\Buttons\\UI-SilverButtonLG-Mid-Up")
    uiElements[i]:SetCheckedTexture("Interface\\BankFrame\\Bank-Background")
end

function hidePlayerRow(i)
    uiElements[i]:Hide();
end

function hideEditBox(self)
    self:SetText("")
    self:ClearFocus();
    self:Hide()
end

function onAddPlayerButtonClicked()
    f.editBox:Show()
end

function onRemovePlayerButtonClicked()
    local i = 0
    while uiElements[i] ~= nil do
        if uiElements[i]:GetChecked() then
            removePlayer(uiElements[i]:GetText())
        end
        i = i + 1
    end
    f.editBox:Hide()
end

function onChatItemClicked()
    print("chat clicked")
end

function showUI()
    f:Show()
end

function hideUI()
    f:Hide()
end

function toggleUI()
    if f:IsShown() then f:Hide()
    else f:Show() end
end

function listPlayers()
    _printList(BlacklistPlayerList);
end

function addPlayer(player, reason)
    if player == nil or player == "" then return print("Add a player to your blacklist with \"/bl add tool\"") end;
    if reason == nil then reason = "" end;
    player = case(player)
    BlacklistPlayerList[player] = reason;
    createPlayerRow(player, count)
    count = count + 1
end

function removePlayer(player)
    if player == nil or player == "" then return print("Remove a player from your blacklist with \"/bl remove tool\"") end;
    player = case(player)
    BlacklistPlayerList[player] = nil;
    local i = 0
    while uiElements[i] ~= nil do
        if uiElements[i]:GetText() == player then
            hidePlayerRow(i)
            break
        end
        i = i + 1
    end
end

function printHelp()
    print("/bl add <player> <reason?>: Add a player to your blacklist with an optional reason");
    print("/bl remove <player>: Remove a player from your blacklist");
    print("/bl list: List all blacklisted players");
    print("/bl: Show the UI for this");
end

function _printList(list)
    if list == nil then list = BlacklistPlayerList end
    for key, value in pairs(list) do
        print(key..": "..value)
    end
end

function getColorCode(msg)
    if msg == "Alliance" then
        return "ff0351b3";
    elseif msg == "Horde" then
        return "ffcc0301";
    elseif msg == "Death Knight" then
        return "ffc41f3b";
    elseif msg == "Demon Hunter" then
        return "ffa330c9";
    elseif msg == "Druid" then
        return "ffff7d0a";
    elseif msg == "Hunter" then
        return "ffabd473";
    elseif msg == "Mage" then
        return "ff40c7eb";
    elseif msg == "Monk" then
        return "ff00ff96";
    elseif msg == "Paladin" then
        return "fff58cba";
    elseif msg == "Priest" then
        return "ffffffff";
    elseif msg == "Rogue" then
        return "fffff569";
    elseif msg == "Shaman" then
        return "ff0070de";
    elseif msg == "Warlock" then
        return "ff8787ed";
    elseif msg == "Warrior" then
        return "ffc79c6e";
    end

    return "ffffffff";
end

-- https://stackoverflow.com/a/7615129
function split (input, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function case (str)
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end

SLASH_BLACKLIST1 = "/blacklist";
SLASH_BLACKLIST2 = "/bl";
SlashCmdList["BLACKLIST"] = function(msg)
    local commands = split(msg);
    local action = commands[1];
    local player = commands[2];
    local reason = commands[3];
    local i = 4
    while commands[i] do
        reason = reason.." "..commands[i]
        i = i + 1
    end
    if action ~= nil then
        if action == "list" then
            listPlayers();
        elseif action == "add" then
            addPlayer(player, reason);
        elseif action == "remove" then
            removePlayer(player);
        elseif action == "help" then
            printHelp();
        elseif action == "clear" then
            BlacklistPlayerList = {}
        elseif action == "show" then
            showUI()
        elseif action == "hide" then
            hideUI()
        else
            print("Command \"" .. msg .. "\" not recognized")
        end
    else
        toggleUI();
    end
end