local addonName, ns = ...
local wticc = WrapTextInColorCode

local eventReceiver = CreateFrame("Frame", "MythicWhispers_EventReceiver")

local activeChats = {}

local currentWhisper = nil
local whisperDuringCombat = false

local lastWhoPlayer = nil

local chatLineSpacing = 3

local chatProvider = CreateDataProvider()

local framePool

local fullPlayerName

ns.F = {}

local invisibleString = UIParent:CreateFontString(nil, "BACKGROUND", "SystemFont_Shadow_Med1")
invisibleString:SetWidth((GetScreenWidth() / 6) - 40)
--invisibleString:Show()

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

local function calculateFontStringWidth(fontstring, text)
    fontstring:SetWidth(2000)
    fontstring:SetText(text)

    return fontstring:GetStringWidth()
end

local function calculateElementExtent(index, data)
    invisibleString:SetHeight(2000)
    invisibleString:SetText(data.text)

    return invisibleString:GetStringHeight() + chatLineSpacing
end

local function calculateFontStringHeight(fontstring, text)
    fontstring:SetHeight(2000)
    fontstring:SetText(text)

    return fontstring:GetStringHeight() + chatLineSpacing
end

local function closeChat(playerName)
    framePool:Release(activeChats[playerName])
    activeChats[playerName] = nil

    if(currentWhisper == playerName) then
        currentWhisper = nil
    end
    
    ns.MainFrame.ChatButtonScrollFrame.Container:MarkDirty()

    local children = ns.MainFrame.ChatButtonScrollFrame.Container:GetLayoutChildren()
    
    if(#children > 0) then
        ns.checkPlayerForChatFrame(children[1].fullName, true)
    
    else
        ns.MainFrame.DataProvider:Flush()
    
    end

    ns.MainFrame.Status:Hide()
end

-- --------------------------------------------------------------------------------------------------------------------------------
-- This is a very long line of words that is way longer than the fontstring itself, which is then going to get resized as a result.

local function addButtonTooltip(playerName, specialFlags)
    activeChats[playerName]:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(playerName)

        if(specialFlags and specialFlags ~= "") then
            GameTooltip:AddLine("Special: " .. specialFlags)
        end
        
        local englishClass = string.sub(MW_ChatLogs[playerName].class, 0, 1) .. string.lower(string.sub(MW_ChatLogs[playerName].class, 2))

        GameTooltip:AddLine("Class: " .. englishClass)
        GameTooltip:AddLine("Race: " .. MW_ChatLogs[playerName].race)

        if(ns.F.IS_RAIDERIO_LOADED) then
            local profile = RaiderIO.GetProfile(playerName)

            if(profile) then
                GameTooltip_AddBlankLineToTooltip(GameTooltip)

                if(profile.mythicKeystoneProfile) then
                    GameTooltip:AddLine("M+ Rating: " .. wticc(profile.mythicKeystoneProfile.currentScore, ns.createCustomColorForRating(profile.mythicKeystoneProfile.currentScore):GenerateHexColor()))

                else
                    GameTooltip:AddLine("M+ Rating: " .. wticc("N/A", ns.CLRSCC.red))
                
                end

                local panelProgressString

                if(profile.raidProfile) then
                    local currentData, _, orderedData = ns.getRaidSortData(playerName)

                    panelProgressString = "\n"

                    local ordinalTable = {}

                    for k, v in ipairs(orderedData) do
                        --panelProgressString = panelProgressString .. v.shortName .. ": " .. wticc(ns.DIFFICULTY[v.difficulty].shortName .. ":" .. v.progress .. "/" .. v.bossCount, ns.DIFFICULTY[v.difficulty].color) .. "\n"
                        if(v.difficulty ~= -1) then
                            if(not ordinalTable[v.ordinal]) then
                                ordinalTable[v.ordinal] = v.shortName .. ": "
                            end

                            ordinalTable[v.ordinal] = ordinalTable[v.ordinal] .. wticc(ns.DIFFICULTY[v.difficulty].shortName .. ":" .. v.progress .. "/" .. v.bossCount, ns.DIFFICULTY[v.difficulty].color) .. " "
                        end
                    end

                    for k, v in ipairs(ordinalTable) do
                        panelProgressString = panelProgressString .. v .. "\n"
                    end
                else
                    panelProgressString = wticc("N/A", ns.CLRSCC.red)
                
                end

                GameTooltip:AddLine("Raid Progress: " .. panelProgressString)

            else
                GameTooltip:AddLine("No RaiderIO data found")
            
            end
        end

        GameTooltip:Show()
    end)

    activeChats[playerName]:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function createChatButton(playerName)
    local chatButton = framePool:Acquire()
    chatButton.layoutIndex = #ns.MainFrame.ChatButtonScrollFrame.Container:GetLayoutChildren() + 1
    chatButton:SetWidth(50)
    chatButton:Show()
    chatButton.fullName = playerName
    chatButton.lastLoadedLog = 0

    local shortName = createShortNameFrom("unitName", playerName)
    local coloredName = wticc(shortName, MW_ChatLogs[playerName].class and C_ClassColor.GetClassColor(MW_ChatLogs[playerName].class):GenerateHexColor() or "FFFFFFFF")

    local specialText = MW_ChatLogs[playerName].specialText and MW_ChatLogs[playerName].specialText .. " " or ""

    local newWidth = calculateFontStringWidth(chatButton.Name, specialText .. coloredName)
    chatButton:SetWidth(newWidth + 30)

    chatButton:SetScript("OnMouseDown", function(self, button)
        if(button == "LeftButton") then
            if(currentWhisper ~= playerName) then
                ns.checkPlayerForChatFrame(playerName, true)
            end
        
            C_FriendList.SetWhoToUi(false)
            lastWhoPlayer = playerName
            C_FriendList.SendWho("n-" .. playerName, 2)
        end
    end)

    chatButton.CloseButton:SetScript("OnClick", function()
        closeChat(playerName)
    end)

    activeChats[playerName] = chatButton

    addButtonTooltip(playerName)

    ns.MainFrame.ChatButtonScrollFrame.Container:MarkDirty()
end

local function loadLastLogs(playerName)
    if(#MW_ChatLogs[playerName].logs > 1) then
        local numberOfLogs = #MW_ChatLogs[playerName].logs

        if(activeChats[playerName].lastLoadedLog + 10 < numberOfLogs) then
            ns.MainFrame.DataProvider:Insert({playerName = playerName, text="BLANK", status = "more"})
        end
        
        for i = 11 + activeChats[playerName].lastLoadedLog, 2, -1 do
            local currentLog = MW_ChatLogs[playerName].logs[numberOfLogs - (i - 1)]

            if(currentLog) then
                currentLog.old = true
                ns.MainFrame.DataProvider:Insert(currentLog)
            end
        end
    end

    if(MW_ChatLogs[playerName].lastMessageSeen == false and currentWhisper ~= playerName) then
        ns.MainFrame.DataProvider:Insert({playerName = playerName, text="BLANK", status = "empty"})
    end
end

local function checkPlayerForChatFrame(playerName, switchToPlayer)
    switchToPlayer = switchToPlayer or #ns.MainFrame.ChatButtonScrollFrame.Container:GetLayoutChildren() == 0
    local playerHasNoChatButton = not activeChats[playerName]

    if(playerHasNoChatButton) then
        createChatButton(playerName)
    
    end

    if(switchToPlayer) then
        ns.MainFrame.DataProvider:Flush()
        
        if(currentWhisper) then
            activeChats[currentWhisper].BackgroundSelected:Hide()

        end

        activeChats[playerName].BackgroundSelected:Show()

        --if(currentWhisper ~= playerName) then
            loadLastLogs(playerName)
        --end

        currentWhisper = playerName
    end

    if(currentWhisper == playerName) then
        ns.MainFrame.DataProvider:Insert(MW_ChatLogs[playerName].logs[#MW_ChatLogs[playerName].logs])
        ns.MainFrame.ScrollBox:ScrollToEnd()

        MW_ChatLogs[playerName].lastMessageSeen = true
        
    else
        activeChats[playerName].BackgroundHighlight:Show()

    end

    ns.MainFrame.ScrollView:SetDataProvider(ns.MainFrame.DataProvider)

    if(not MW_ChatLogs[playerName].isFriend and not MW_ChatLogs[playerName].whitelisted) then
        ns.MainFrame.ScrollBox:Hide()
        ns.MainFrame.Status:Show()

    else
        ns.MainFrame.ScrollBox:Show()
        ns.MainFrame.Status:Hide()
    
    end

    if(not ns.MainFrame:IsShown() and not InCombatLockdown()) then

        ns.MainFrame:Show()
    end
end

ns.checkPlayerForChatFrame = checkPlayerForChatFrame

local function Initializer(frame, data)
    if(not data.status) then
        local newTimestamp

        if(date("%d") ~= data.day or date("%m") ~= data.month) then
            newTimestamp = data.day .. "/" .. data.month .. " " .. data.timestamp
        else
            newTimestamp = data.timestamp
        end

        local newWidth = calculateFontStringWidth(frame.Timestamp, "[" .. newTimestamp .. "]")
        frame.Timestamp:SetWidth(newWidth)

        local newHeight = calculateFontStringHeight(frame.Text, data.text)
        frame.Text:SetHeight(newHeight)

        if(data.old) then
            frame.Text:SetTextColor(0.4, 0.4, 0.4, 1)

        else
            frame.Text:SetTextColor(1, 1, 1, 1)

        end
    else
        if(data.status == "empty") then
            frame.Timestamp:SetText("")
            frame.Text:SetText("")
        
        elseif(data.status == "more") then
            frame.Timestamp:SetText("")
            frame.Text:SetTextColor(1, 1, 1, 1)
            frame.Text:SetText("There are more messages...")
            frame.layoutIndex = -99999999
            frame:SetScript("OnMouseDown", function()
                activeChats[data.playerName].lastLoadedLog = activeChats[data.playerName].lastLoadedLog + 10

                checkPlayerForChatFrame(data.playerName, true)
                
            end)
        end
    end
end

local function createMainFrame()
    local realm = GetNormalizedRealmName()

    if(realm) then
        local shortName, realm2 = UnitFullName("player")

        if(shortName and realm2) then
            fullPlayerName = shortName .. "-" .. realm2

        else
            fullPlayerName = UnitName("player") .. "-" .. realm
        
        end
    end

    ns.MainFrame = CreateFrame("Frame", "MythicWhispers_MainFrame", UIParent, "MW_MainFrame")
    ns.MainFrame:SetSize(GetScreenWidth() / 6, GetScreenHeight() / 6)
    ns.createFrameBorder(ns.MainFrame, 2, CreateColorFromHexString("FF3C3D4E"):GetRGBA())
    ns.MainFrame.Background:SetTexture("Interface/Addons/" .. addonName .. "/res/backgrounds/df-bg-1_small.png")
    ns.MainFrame.LogBox.Background:SetTexture("Interface/Addons/" .. addonName .. "/res/backgrounds/df-bg-1_small.png")

    ns.MainFrame.ChatButtonScrollFrame.ScrollBar:Hide()

	if(ns.MainFrame:GetPoint() == nil) then
		ns.MainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", GetScreenWidth() / 6, - GetScreenHeight() / 6)

    end

    ns.MainFrame.ChatBox:SetScript("OnKeyDown", function(self, key)
        if(key == "ENTER") then
            SendChatMessage(sanitizeTextInput(self:GetText()), "WHISPER", select(2, GetDefaultLanguage()), currentWhisper)
            self:SetText("")
        end
    end)

    local ScrollView = CreateScrollBoxListLinearView()
    ScrollUtil.InitScrollBoxListWithScrollBar(ns.MainFrame.ScrollBox, ns.MainFrame.ScrollBar, ScrollView)

    ScrollView:SetElementInitializer("MW_ChatLineTemplate", Initializer)
    ScrollView:SetElementExtentCalculator(function(index, data)
        return calculateElementExtent(index, data)
        --calculateFontStringHeight
    end)

    ns.MainFrame.ScrollView = ScrollView

    --ScrollView:SetPadding(4, 2, 2, 2, 4)
    
    local logScrollView = CreateScrollBoxListLinearView()

    ScrollUtil.InitScrollBoxListWithScrollBar(ns.MainFrame.LogBox, ns.MainFrame.LogBox.ScrollBar, logScrollView)

    logScrollView:SetElementInitializer("MW_LogLineTemplate", function(frame, data)
        frame.Name:SetText(wticc(data.name, C_ClassColor.GetClassColor(MW_ChatLogs[data.name].class):GenerateHexColor()))
        frame:SetScript("OnMouseDown", function()
            checkPlayerForChatFrame(data.name, true)
        end)
    end)
    logScrollView:SetPadding(2, 2, 2, 2, 4)

    ns.MainFrame.LogButton:SetScript("OnClick", function(self, button)
        if(not ns.MainFrame.LogBox:IsShown()) then
            local alphabeticallyOrderedList = {}

            for k in pairs(MW_ChatLogs) do
                alphabeticallyOrderedList[#alphabeticallyOrderedList+1] = k

            end

            table.sort(alphabeticallyOrderedList, function(k1, k2)
                return k1 < k2
            end)

            ns.MainFrame.LogBox.dataProvider = CreateDataProvider()

            for _, v in pairs(alphabeticallyOrderedList) do
                ns.MainFrame.LogBox.dataProvider:Insert({name = v})

            end

            logScrollView:SetDataProvider(ns.MainFrame.LogBox.dataProvider)

            ns.MainFrame.LogBox:Show()

        else
            ns.MainFrame.LogBox:Hide()
        
        end
    end)

    ns.MainFrame.DataProvider = CreateDataProvider()

    framePool = CreateFramePool("Frame", ns.MainFrame.ChatButtonScrollFrame.Container, "MW_ChatButton", function(_, frame)
        frame:Hide()
        frame.BackgroundSelected:Hide()
        frame.BackgroundHighlight:Hide()
        frame.layoutIndex = nil

        frame.Name:SetText("")
        frame.Status:SetColorTexture(0.25, 0.25, 0.25, 1)
        frame.CloseButton:SetScript("OnClick", nil)
        frame:SetScript("OnEnter", nil)
        frame.fullName = nil
        frame.lastLoadedLog = nil

        frame:SetScript("OnMouseDown", nil)
    end)

    ns.MainFrame.Status.WhitelistButton:SetScript("OnClick", function()
        MW_ChatLogs[currentWhisper].whitelisted = true
        ns.MainFrame.ScrollBox:Show()

        ns.MainFrame.Status:Hide()
    end)

    ns.MainFrame.Status.DeleteButton:SetScript("OnClick", function()
        MW_ChatLogs[currentWhisper] = nil
        ns.MainFrame.DataProvider:Flush()
        ns.MainFrame.ScrollBox:Show()

        closeChat(currentWhisper)
    end)

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
                activeChats[info.fullName].Status:SetColorTexture(0,1,0,1)
            end
        end
    elseif(activeChats[lastWhoPlayer]) then
        activeChats[lastWhoPlayer].Status:SetColorTexture(1,0,0,1)

    end
end

-- /run MW_ChatLogs["Rhany-Ravencrest"] = nil

local function mainEvents(_, event, ...)
	if(event == "PLAYER_LOGIN") then
        createMainFrame()

		if(C_AddOns.IsAddOnLoaded("RaiderIO")) then
			ns.F.IS_RAIDERIO_LOADED = true

		end

        if(not MW_ChatLogs) then
            MW_ChatLogs = {}
        end

    elseif(event == "CHAT_MSG_WHISPER") then
        local text, senderName, languageName, channelName, targetName, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(guid)

        local logPlayerName = fullPlayerName ~= senderName and senderName or targetName or fullPlayerName

        if(not MW_ChatLogs[logPlayerName]) then
            MW_ChatLogs[logPlayerName] = {class = englishClass, race = englishRace, logs = {}}
            
            if(ns.MainFrame.LogBox:IsShown()) then
                ns.MainFrame.LogBox.dataProvider:Insert({name = logPlayerName})
            end

        end

        MW_ChatLogs[logPlayerName].specialText = ns.getPFlag(specialFlags, zoneChannelID)
        MW_ChatLogs[logPlayerName].lastMessageSeen = false
        MW_ChatLogs[logPlayerName].isFriend = C_FriendList.IsFriend(guid)

        local data = {timestamp = date("%H:%M:%S"), day = date("%d"), month = date("%m"), year = date("%y"), text = text}

        if(senderName == fullPlayerName) then
            data.type = "out"

        else
            data.type = "in"
        
        end

        table.insert(MW_ChatLogs[logPlayerName].logs, data)

        checkPlayerForChatFrame(logPlayerName)

        --PlaySound(SOUNDKIT.TELL_MESSAGE);

        addButtonTooltip(logPlayerName, specialFlags)
    elseif(event == "PLAYER_REGEN_DISABLED") then
        ns.MainFrame:Hide()

    elseif(event == "PLAYER_REGEN_ENABLED") then
        if(whisperDuringCombat) then
            whisperDuringCombat = false
            ns.MainFrame:Show()

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



SLASH_MW1 = '/mw'
local function handler(msg, editBox)
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if(command == "") then
        if(not InCombatLockdown()) then
            ns.MainFrame:Show()
        end
	end
end
SlashCmdList["MW"] = handler