local addonName, mw = ...
local wticc = WrapTextInColorCode

local eventReceiver = CreateFrame("Frame", "MythicWhispers_EventReceiver")

local activeChats = {}

local currentWhisper = nil
local whisperDuringCombat = false

local lastWhoPlayer = nil
local whoPlayers = {}

local function sanitizeTextInput(text)
    if(strlen(text) > 255) then
        text = string.sub(text, 0, 255)
    end

    return text
end

local function simpleSplit(tempString, delimiter)
	local resultArray = {}
	for result in string.gmatch(tempString, "[^"..delimiter.."]+") do
		resultArray[#resultArray+1] = result
	end

	return resultArray

end

local function createShortNameFrom(type, value)
	if(type == "unitID") then
		return UnitName(value)

	else
		local nameTable = simpleSplit(value, "-")

		if(not nameTable[2]) then
			return value

		else
			return nameTable[1]

		end
	end
end

local function createFrameBorder(frame, thickness, r, g, b, a)
	frame:SetBackdrop( { bgFile="Interface\\ChatFrame\\ChatFrameBackground", tileSize=20, tile=false, edgeFile="Interface\\ChatFrame\\ChatFrameBackground", edgeSize = thickness} )
	frame:SetBackdropColor(0, 0, 0, 0) -- main area color
	frame:SetBackdropBorderColor(r or random(0, 1), g or random(0, 1), b or random(0, 1), a or 1) -- border color

end

local function xyz()
    mw.MainFrame = CreateFrame("Frame", "MythicWhispers_MainFrame", UIParent, "MW_MainFrame")
    mw.MainFrame:SetSize(GetScreenWidth() / 6, GetScreenHeight() / 6)
    createFrameBorder(mw.MainFrame, 2, CreateColorFromHexString("FF3C3D4E"):GetRGBA())

    mw.MainFrame.Background:SetTexture("Interface/Addons/" .. addonName .. "/res/backgrounds/df-bg-1_small.png")

	if(mw.MainFrame:GetPoint() == nil) then
		mw.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", GetScreenWidth() / 6, - GetScreenHeight() / 6)

    end

    mw.MainFrame.ChatBox:SetScript("OnKeyDown", function(self, key)
        if(key == "ENTER") then
            SendChatMessage(sanitizeTextInput(self:GetText()), "WHISPER", select(2, GetDefaultLanguage()), currentWhisper)
            self:SetText("")
        end
    end)
end

local function Initializer(frame, data)
    frame.Timestamp:SetText("[" .. data.timestamp .. "]")
    frame.Text:SetText(data.text)
end

-- --------------------------------------------------------------------------------------------------------------------------------
-- This is a very long line of words that is way longer than the fontstring itself, which is then going to get resized as a result.

local function setCurrentWhisperTarget(playerName)
    if(currentWhisper) then
        activeChats[currentWhisper].frame.BackgroundSelected:Hide()
        activeChats[currentWhisper].scrollBox:Hide()
        activeChats[currentWhisper].scrollBar:Hide()
    end

    if(playerName) then
        activeChats[playerName].frame:Show()
        activeChats[playerName].scrollBox:Show()
        activeChats[playerName].scrollBar:Show()
        activeChats[playerName].frame.BackgroundSelected:Show()
    end
    
    currentWhisper = playerName
end

local invisibleString = UIParent:CreateFontString(nil, "BACKGROUND", "SystemFont_Shadow_Med1")
invisibleString:SetWidth((GetScreenWidth() / 6) - 80)
invisibleString:Show()

local function createNewChatFrame(playerName, class)
    activeChats[playerName] = {
        frame = CreateFrame("Frame", nil, mw.MainFrame.ChatsBar, "MW_ChatButton"),
        scrollBox = CreateFrame("Frame", nil, mw.MainFrame, "WowScrollBoxList"),
        scrollBar = CreateFrame("EventFrame", nil, mw.MainFrame, "MinimalScrollBar"),
        dataProvider = CreateDataProvider()
    }

    activeChats[playerName].frame.layoutIndex = #mw.MainFrame.ChatsBar:GetLayoutChildren() + 1

    activeChats[playerName].scrollBox:SetPoint("TOPLEFT", mw.MainFrame.ChatsBar, "BOTTOMLEFT", 0, -3)
    activeChats[playerName].scrollBox:SetPoint("BOTTOMRIGHT", mw.MainFrame.ChatBox, "TOPRIGHT", -(activeChats[playerName].scrollBar:GetWidth() + 5), 3)

    activeChats[playerName].scrollBar:SetPoint("TOPLEFT", activeChats[playerName].scrollBox, "TOPRIGHT")
    activeChats[playerName].scrollBar:SetPoint("BOTTOMLEFT", activeChats[playerName].scrollBox, "BOTTOMRIGHT")

    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(activeChats[playerName].dataProvider)
    
    ScrollUtil.InitScrollBoxListWithScrollBar(activeChats[playerName].scrollBox, activeChats[playerName].scrollBar, ScrollView)

    ScrollView:SetElementInitializer("MW_ChatLineTemplate", Initializer)
    ScrollView:SetElementExtentCalculator(function(index, data)
        invisibleString:SetHeight(2000)
        invisibleString:SetText(data.text)
        return invisibleString:GetStringHeight()
    end)
    ScrollView:SetPadding(4, 2, 2, 2, 4)

    local displayName = createShortNameFrom("unitName", playerName)

    activeChats[playerName].frame.Name:SetWidth(2000)
    activeChats[playerName].frame.Name:SetText(wticc(displayName, C_ClassColor.GetClassColor(class):GenerateHexColor()))
    activeChats[playerName].frame.Name:SetWidth(activeChats[playerName].frame.Name:GetStringWidth())
    activeChats[playerName].frame:SetWidth(activeChats[playerName].frame.Name:GetWidth() + 34)

    activeChats[playerName].frame.Status:SetColorTexture(0.25, 0.25, 0.25, 1)
    activeChats[playerName].frame:SetScript("OnMouseDown", function()
        setCurrentWhisperTarget(playerName)

        whoPlayers[playerName] = true
        C_FriendList.SetWhoToUi(false)
        lastWhoPlayer = playerName
        C_FriendList.SendWho("n-" .. playerName, 2)
    end)

    activeChats[playerName].frame.CloseButton:SetScript("OnClick", function(self)
        activeChats[playerName].frame:Hide()
        activeChats[playerName].scrollBox:Hide()
        activeChats[playerName].scrollBar:Hide()
        activeChats[playerName].frame.layoutIndex = nil

        local children = mw.MainFrame.ChatsBar:GetLayoutChildren()
        
        if(#children > 0) then
            local newName = children[1].Name:GetText()
            setCurrentWhisperTarget(newName)

            mw.MainFrame.ChatsBar:MarkDirty()
        else
            setCurrentWhisperTarget()
        
        end

    end)
end

local function addMessageToChat(text, playerName, class)
    if(not MW_ChatLogs[playerName]) then
        MW_ChatLogs[playerName] = {}
    end

    local data = {timestamp = date("%H:%M:%S"), day = date("%d"), month = date("%m"), year = date("%y"), text = text}

    table.insert(MW_ChatLogs[playerName], data)

    if(not activeChats[playerName]) then
        createNewChatFrame(playerName, class)
    end

    activeChats[playerName].dataProvider:Insert(data)

    if(currentWhisper == nil) then
        setCurrentWhisperTarget(playerName)

        activeChats[playerName].frame.layoutIndex = #mw.MainFrame.ChatsBar:GetLayoutChildren() + 1

        mw.MainFrame.ChatsBar:MarkDirty()
    end

    --local fontString = activeChats[playerName].pool:Acquire()
    --fontString:SetFont("SystemFont_Shadow_Med1", 10, "OUTLINE")
    --fontString:SetText(text)
    --fontString.layoutIndex = #activeChats[playerName].Container:GetLayoutChildren() + 1
    --fontString:Show()

    --activeChats[playerName].Container:MarkDirty()
end

local function checkOnlineStatus()
    local numResults = C_FriendList.GetNumWhoResults()

    if(numResults > 0) then
        for i = 1, numResults, 1 do
            local info = C_FriendList.GetWhoInfo(i)

            if(info.fullName == UnitName("player")) then
                info.fullName = info.fullName .. "-" .. GetNormalizedRealmName()
            end

            if(activeChats[info.fullName]) then
                whoPlayers[info.fullName] = nil
                activeChats[info.fullName].frame.Status:SetColorTexture(0,1,0,1)
            end
        end
    elseif(activeChats[lastWhoPlayer]) then
        activeChats[lastWhoPlayer].frame.Status:SetColorTexture(1,0,0,1)

    end
end

local function mainEvents(_, event, ...)
	if(event == "PLAYER_LOGIN") then
        xyz()

        if(not MW_ChatLogs) then
            MW_ChatLogs = {}
        end

    elseif(event == "CHAT_MSG_WHISPER") then
        local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(guid)
        addMessageToChat(text, playerName, englishClass)

        if(InCombatLockdown()) then
            whisperDuringCombat = true
            
        else
            mw.MainFrame:Show()
        
        end
    elseif(event == "PLAYER_REGEN_DISABLED") then
        mw.MainFrame:Hide()

    elseif(event == "PLAYER_REGEN_ENABLED") then
        if(whisperDuringCombat) then
            whisperDuringCombat = false
            mw.MainFrame:Show()

        end

    elseif(event == "WHO_LIST_UPDATE") then
        checkOnlineStatus()

    elseif(event == "CHAT_MSG_SYSTEM") then
        checkOnlineStatus()

    end
end

eventReceiver:RegisterEvent("PLAYER_LOGIN")
eventReceiver:RegisterEvent("PLAYER_REGEN_DISABLED")
eventReceiver:RegisterEvent("PLAYER_REGEN_ENABLED")
eventReceiver:RegisterEvent("WHO_LIST_UPDATE")
eventReceiver:RegisterEvent("CHAT_MSG_WHISPER")
eventReceiver:RegisterEvent("CHAT_MSG_SYSTEM")
eventReceiver:SetScript("OnEvent", mainEvents)

function MW_OpenInterfaceOptions()
	Settings.OpenToCategory("MythicWhispers")
end