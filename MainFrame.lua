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

ns.F = {}

local invisibleString = UIParent:CreateFontString(nil, "BACKGROUND", "SystemFont_Shadow_Med1")
invisibleString:SetWidth((GetScreenWidth() / 6) - 80)
invisibleString:Show()

local function calculateElementExtent(index, data)
    invisibleString:SetHeight(2000)
    invisibleString:SetText(data.text)

    return invisibleString:GetStringHeight() + invisibleString:GetNumLines() * chatLineSpacing
end

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

local function calculateFontStringHeight(fontstring, text)
    fontstring:SetHeight(2000)
    fontstring:SetText(text)

    return fontstring:GetStringHeight() + fontstring:GetNumLines() * chatLineSpacing
end

local function createFrameBorder(frame, thickness, r, g, b, a)
	frame:SetBackdrop( { bgFile="Interface\\ChatFrame\\ChatFrameBackground", tileSize=20, tile=false, edgeFile="Interface\\ChatFrame\\ChatFrameBackground", edgeSize = thickness} )
	frame:SetBackdropColor(0, 0, 0, 0) -- main area color
	frame:SetBackdropBorderColor(r or random(0, 1), g or random(0, 1), b or random(0, 1), a or 1) -- border color

end

local function createNewDataProvider()
    ns.MainFrame.dataProvider = CreateDataProvider()
    ns.MainFrame.ScrollView:SetDataProvider(ns.MainFrame.dataProvider)

end

local function addNewestMessageToChat(playerName, text)
    if(currentWhisper == playerName) then
        ns.MainFrame.dataProvider:Insert(text)

    end
end

local function loadTenLogLines(playerName)
    if(#MW_ChatLogs[playerName].logs > 0) then
        local numberOfLogs = #MW_ChatLogs[playerName].logs

        ns.MainFrame.ScrollView:SetDataProvider(ns.MainFrame.dataProvider)

        if(numberOfLogs > 10 + activeChats[playerName].lastLoadedLog) then
            ns.MainFrame.dataProvider:Insert({status = "more", text = "BLANK", playerName = playerName})
            
        end
        
        for i = 11 + activeChats[playerName].lastLoadedLog, 2, -1 do
            local currentLog = MW_ChatLogs[playerName].logs[numberOfLogs - (i - 1)]
            
            if(currentLog) then
                currentLog.old = true
                ns.MainFrame.dataProvider:Insert(currentLog)

            end
        end

        local lastMessage = MW_ChatLogs[playerName].logs[numberOfLogs]

        if(#MW_ChatLogs[playerName].logs > 1) then
            ns.MainFrame.dataProvider:Insert({status = "empty", text = "BLANK", playerName})
        end

        ns.MainFrame.dataProvider:Insert(lastMessage)
    end
end

local function loadChatFrame(playerName, loadLogs, switchView)
    createNewDataProvider()

    if(switchView) then
        activeChats[playerName].lastLoadedLog = 0

    end

    if(loadLogs) then
        loadTenLogLines(playerName)
    end

    if(switchView) then

        if(currentWhisper) then
            activeChats[currentWhisper].BackgroundSelected:Hide()
        end

        if(playerName) then
            if(activeChats[playerName]) then
                activeChats[playerName].BackgroundSelected:Show()
                currentWhisper = playerName
                ns.MainFrame.ScrollBox:ScrollToEnd()

            end
            
        end
    else
        ns.MainFrame.ScrollBox:ScrollToBegin()
    
    end

    ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:MarkDirty()
end

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
                loadChatFrame(data.playerName, true, false)

                activeChats[data.playerName].lastLoadedLog = activeChats[data.playerName].lastLoadedLog + 10
                
            end)
        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------------------
-- This is a very long line of words that is way longer than the fontstring itself, which is then going to get resized as a result.

local function closeChatFrame(playerName)
    playerName = playerName
    framePool:Release(activeChats[playerName])
    activeChats[playerName] = nil

    if(currentWhisper == playerName) then
        currentWhisper = nil
    end

    local children = ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren()
    local newName

    createNewDataProvider()
    
    if(#children > 0) then
        loadChatFrame(children[1].fullName, true, true)
    
    end
end
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
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
            local profile = RaiderIO.GetProfile(playerName)

            if(profile) then
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

                        if(not ordinalTable[v.ordinal]) then
                            ordinalTable[v.ordinal] = v.shortName .. ": "
                        end

                        ordinalTable[v.ordinal] = ordinalTable[v.ordinal] .. wticc(ns.DIFFICULTY[v.difficulty].shortName .. ":" .. v.progress .. "/" .. v.bossCount, ns.DIFFICULTY[v.difficulty].color) .. " "
                    end

                    for k, v in ipairs(ordinalTable) do
                        panelProgressString = panelProgressString .. v .. "\n"
                    end
                else
                    panelProgressString = wticc("N/A", ns.CLRSCC.red)
                
                end

                GameTooltip:AddLine("Raid Progress: " .. panelProgressString)
            end
        end

        GameTooltip:Show()
    end)

    activeChats[playerName]:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function createNewChatFrame(playerName)
    local chatButton = framePool:Acquire()

    activeChats[playerName] = chatButton

    local shortName = createShortNameFrom("unitName", playerName)

    local newWidth = calculateFontStringWidth(chatButton.Name, wticc(shortName, MW_ChatLogs[playerName].class and C_ClassColor.GetClassColor(MW_ChatLogs[playerName].class):GenerateHexColor() or "FFFFFFFF"))
    chatButton:SetWidth(newWidth + 30)
    chatButton.fullName = playerName
    chatButton.lastLoadedLog = 0
    chatButton:SetParent(ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer)
    chatButton.layoutIndex = #ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren() + 1
    chatButton:Show()

    chatButton:SetScript("OnMouseDown", function(self, button)
        if(button == "RightButton") then
            ns.MainFrame.RightClickMenu:ResetDropDown()

            local info = {}

            info.index = 1
            info.entryType = "option"
            info.text = "Test"
            info.value = 1
            info.radioHidden = true
            info.func = function()

            end

            ns.MainFrame.RightClickMenu:CreateEntryFrame(info)
            ns.MainFrame.RightClickMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            ns.MainFrame.RightClickMenu:Click()

        elseif(button == "LeftButton") then
            loadChatFrame(playerName, true, true)
        
            C_FriendList.SetWhoToUi(false)
            lastWhoPlayer = playerName
            C_FriendList.SendWho("n-" .. playerName, 2)
        end

    end)

    chatButton.CloseButton:SetScript("OnClick", function(self)
        closeChatFrame(playerName)
    end)

    addButtonTooltip(playerName)

    ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:MarkDirty()

    if(ns.MainFrame.ChatButtonScrollFrame:GetHorizontalScrollRange() > 0) then
        ns.MainFrame.CycleLeft:Enable()
        ns.MainFrame.CycleRight:Enable()
    end

    if(currentWhisper == nil) then
        loadChatFrame(playerName, true, true)

        activeChats[playerName].lastLoadedLog = activeChats[playerName].lastLoadedLog + 10
    end
end

local function jumpToChatButton(playerName)
    local children = ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren()

    local endOfLastChild = 0

    for k, v in ipairs(children) do
        endOfLastChild = endOfLastChild + v:GetWidth()

        if(playerName == v.fullName) then
            if(endOfLastChild > ns.MainFrame.ChatButtonScrollFrame:GetWidth()) then
                ns.MainFrame.ChatButtonScrollFrame:SetHorizontalScroll(endOfLastChild - ns.MainFrame.ChatButtonScrollFrame:GetWidth())

                if(k == 1) then
                    ns.MainFrame.CycleLeft:Disable()

                else
                    ns.MainFrame.CycleLeft:Enable()
                
                end

                if(k == #children) then
                    ns.MainFrame.CycleRight:Disable()
                    
                else
                    ns.MainFrame.CycleRight:Enable()
                
                end
            else
                ns.MainFrame.ChatButtonScrollFrame:SetHorizontalScroll(0)
            
            end
        end
    end

    loadChatFrame(playerName, true, true)

end

local function xyz()
    ns.MainFrame = CreateFrame("Frame", "MythicWhispers_MainFrame", UIParent, "MW_MainFrame")
    ns.MainFrame:SetSize(GetScreenWidth() / 6, GetScreenHeight() / 6)
    createFrameBorder(ns.MainFrame, 2, CreateColorFromHexString("FF3C3D4E"):GetRGBA())
    ns.MainFrame.Background:SetTexture("Interface/Addons/" .. addonName .. "/res/backgrounds/df-bg-1_small.png")
    ns.MainFrame.LogBox.Background:SetTexture("Interface/Addons/" .. addonName .. "/res/backgrounds/df-bg-1_small.png")

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
    end)
    ScrollView:SetPadding(4, 2, 2, 2, 4)

    ns.MainFrame.ScrollView = ScrollView
    
    local logScrollView = CreateScrollBoxListLinearView()

    ScrollUtil.InitScrollBoxListWithScrollBar(ns.MainFrame.LogBox, ns.MainFrame.LogBox.ScrollBar, logScrollView)

    logScrollView:SetElementInitializer("MW_LogLineTemplate", function(frame, data)
        frame.Name:SetText(wticc(data.name, C_ClassColor.GetClassColor(MW_ChatLogs[data.name].class):GenerateHexColor()))
        frame:SetScript("OnMouseDown", function()
            if(not activeChats[data.name]) then
                createNewChatFrame(data.name, class)

            end
            
            if(#ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren() > 1) then
                loadChatFrame(data.name, true, true)
            
            end

            jumpToChatButton(data.name)
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

    ns.MainFrame.RightClickMenu:OnLoad()
    ns.MainFrame.RightClickMenu:SetRightClickMenuMode()

    ns.MainFrame.ChatButtonScrollFrame.ScrollBar:Hide()

    ns.MainFrame.CycleLeft:Disable()
    ns.MainFrame.CycleRight:Disable()
    
    ns.MainFrame.CycleLeft:SetScript("OnClick", function()
        local children = ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren()

        for k, v in ipairs(children) do
            if(v.fullName == currentWhisper) then
                print(v.fullName)
                jumpToChatButton(children[k - 1].fullName)
            end
        end
    end)
    
    ns.MainFrame.CycleRight:SetScript("OnClick", function()
        local children = ns.MainFrame.ChatButtonScrollFrame.ChatButtonContainer:GetLayoutChildren()

        for k, v in ipairs(children) do
            if(v.fullName == currentWhisper) then
                jumpToChatButton(children[k + 1].fullName)
            end
        end
    end)

    framePool = CreateFramePool("Frame", ns.MainFrame, "MW_ChatButton", function(_, frame)
        frame:Hide()
        frame.BackgroundSelected:Hide()
        frame.layoutIndex = nil

        frame.Name:SetText("")
        frame.Status:SetColorTexture(0.25, 0.25, 0.25, 1)
        frame.CloseButton:SetScript("OnClick", nil)
        frame:SetScript("OnEnter", nil)
        frame.fullName = nil
        frame.lastLoadedLog = nil

        frame:SetScript("OnMouseDown", nil)
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
        xyz()

		if(C_AddOns.IsAddOnLoaded("RaiderIO")) then
			ns.F.IS_RAIDERIO_LOADED = true

		end

        if(not MW_ChatLogs) then
            MW_ChatLogs = {}
        end

    elseif(event == "CHAT_MSG_WHISPER") then
        local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(guid)

        if(not MW_ChatLogs[playerName]) then
            MW_ChatLogs[playerName] = {class = englishClass, race = englishRace, logs = {}}
            
            if(ns.MainFrame.LogBox:IsShown()) then
                ns.MainFrame.LogBox.dataProvider:Insert({name = playerName})
            end

        end

        local newChat = not activeChats[playerName]

        if(newChat) then
            createNewChatFrame(playerName)
        
        end

        local data = {timestamp = date("%H:%M:%S"), day = date("%d"), month = date("%m"), year = date("%y"), text = text}
        table.insert(MW_ChatLogs[playerName].logs, data)

        if(not newChat) then
            addNewestMessageToChat(playerName, data)
        end

        addButtonTooltip(playerName, specialFlags)

        if(InCombatLockdown()) then
            whisperDuringCombat = true
            
        else
            ns.MainFrame:Show()
        
        end
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