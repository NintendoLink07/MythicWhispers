AppFrameChatOverviewMixin = CreateFromMixins(CallbackRegistryMixin)

local dataProvider = CreateDataProvider()
local whoTimer

local LINE_HEIGHT = 12
local MAX_NUM_CHARACTERS_PER_LINE = 26
local playerNotFoundStringTable = strsplittable(" ", ERR_CHAT_PLAYER_NOT_FOUND_S)

AppFrameChatOverviewMixin:GenerateCallbackEvents({
    "MythicWhispers.OpenConversation"
})

function AppFrameChatOverviewMixin.SetVerticalPoint(frame, offset, indent, scrollTarget)
	frame:ClearAllPoints();

    local data = frame:GetData()

    if(data.sender == "character") then
	    frame:SetPoint("TOPLEFT", scrollTarget, "TOPLEFT", indent, -offset);
        
    elseif(data.sender == "player") then
	    frame:SetPoint("TOPRIGHT", scrollTarget, "TOPRIGHT", -indent, -offset);

    else
	    frame:SetPoint("TOP", scrollTarget, "TOP", indent, -offset);

    end
    
	return frame:GetHeight();
end

function AppFrameChatOverviewMixin:HasOpenConversation()
    return self.hasOpenConversation

end

function AppFrameChatOverviewMixin:GetOpenConversationName()
    return self.name

end

function AppFrameChatOverviewMixin:CancelWhoTimer()
    if(whoTimer) then
        whoTimer:Cancel()
        whoTimer = nil

    end
end

function AppFrameChatOverviewMixin:SendWho(playerName)
    self:CancelWhoTimer()
    self.Header.LoadingSpinner:Show()

    whoTimer = C_Timer.NewTimer(3, function()
        EventRegistry:TriggerEvent("MythicWhispers.ReceivedWho", false, false)

    end)

    C_FriendList.SetWhoToUi(false)
    C_FriendList.SendWho("n-"..playerName, 1)

end

function AppFrameChatOverviewMixin:OnLoad()
    self.hasOpenConversation = false

    CallbackRegistryMixin.OnLoad(self)
	EventRegistry:RegisterCallback("MythicWhispers.OpenVoiceChatRoom", function() self:Hide() end, self);
	EventRegistry:RegisterCallback("MythicWhispers.OpenConversation", self.OpenConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.CloseConversation", self.CloseCurrentConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.RefreshConversation", self.RefreshOpenConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.ReceivedWho", self.UpdateWhoData, self);
	EventRegistry:RegisterCallback("MythicWhispers.SendWho", self.SendWho, self);

    local view = CreateScrollBoxListLinearView();
    view:SetElementStretchDisabled(true)
    view.GetLayoutFunction = function()
        local setPoint = self.SetVerticalPoint;
        local scrollTarget = view:GetScrollTarget();
        local function Layout(index, frame, offset)
            local indent = view:GetElementIndent(frame);
            return setPoint(frame, offset, indent, scrollTarget);
        end
        return Layout;
    end
    view:SetElementExtentCalculator(function(dataIndex, data)
        if(data.message) then
            local stringWidth = strlen(data.message)

            for i = 1, 100, 1 do
                if(stringWidth < i * MAX_NUM_CHARACTERS_PER_LINE) then
                    return i * LINE_HEIGHT + 18;

                end
            end
        else
            return LINE_HEIGHT + 40

        end
    end)

    function MW_CreateConversationText(frame, data)
        frame:Refresh()

    end

    view:SetElementFactory(function(factory, data)
        local template = data.template
        factory(template, MW_CreateConversationText)

    end)
    view:SetPadding(14, 14, 16, 16, 6);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

	--[[local scrollBoxAnchorsWithoutBar = {
		CreateAnchor("TOPLEFT", self.Header, "BOTTOMLEFT", 0, 0),
		CreateAnchor("BOTTOMRIGHT", self.EditBoxContainer, "TOPRIGHT", -28, 0);
	}
    
	local scrollBoxAnchorsWithBar = {
		scrollBoxAnchorsWithoutBar[1],
		CreateAnchor("BOTTOMRIGHT", self.EditBoxContainer, "TOPRIGHT", -28, 0);
	}

	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)]]

    self.ScrollBox:SetDataProvider(dataProvider)

	local defaultLanguage, defaultLanguageId = GetDefaultLanguage();

    self.EditBoxContainer.ChatBox:SetScript("OnEnterPressed", function(selfBox, ...)
        if(self.name) then
            C_ChatInfo.SendChatMessage(selfBox:GetText(), "WHISPER", defaultLanguageId, self.name)
            selfBox:SetText("")
            selfBox:ClearFocus()

        end
    end)
    
    self:SetScript("OnEvent", function(selfFrame, event, ...)
        if(event == "CHAT_MSG_SYSTEM") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...

            if(text == format(WHO_NUM_RESULTS, 1)) then
                EventRegistry:TriggerEvent("MythicWhispers.ReceivedWho", true, true)

            elseif(text == format(WHO_NUM_RESULTS, 0)) then
                EventRegistry:TriggerEvent("MythicWhispers.ReceivedWho", true, false)

            else
                --[[for k, v in pairs(playerNotFoundStringTable) do
                    if(not string.find(text, v)) then
                        return

                    end
                end]]
            end
        end
    end)
    self:RegisterEvent("CHAT_MSG_SYSTEM")

end

function AppFrameChatOverviewMixin:SetMessages(playerName)
    local logs = MW_ChatLogs[playerName]

    if(logs) then
        local messages = logs.messages

        local numOfMessages = #messages

        local lastDate = C_DateAndTime.GetCurrentCalendarTime()

        for i = max(1, numOfMessages - 200), numOfMessages, 1 do
            local v = messages[i]
            local newDate = v.date

            if(not CalendarUtil.AreDatesEqual(lastDate, newDate)) then
                dataProvider:Insert({
                    template = "MW_AppFrameConversationDaystamp",
                    date = newDate,
                })

                lastDate = newDate
            end

            if(v.viewed == false) then
                logs.numOfUnreadMessages = logs.numOfUnreadMessages - 1
                v.viewed = true

                EventRegistry:TriggerEvent("MythicWhispers.SendMessageRead", playerName, newDate, v.message)

                self:GetParent().ChatList:RefreshConversationButtons()
            end

            dataProvider:Insert({
                template = "MW_AppFrameConversationMessage",
                read = v.read,
                sender= v.sender,
                message = v.message,
                date = newDate,
            })

        end
    end
    
    self.ScrollBox:ScrollToEnd()
end

function AppFrameChatOverviewMixin:CloseCurrentConversation()
    if(self.name) then
        self.Header:Hide()
        self.EditBoxContainer:Hide()

        self.name = nil
        self.hasOpenConversation = false

    end
    
    dataProvider:Flush()
end

function AppFrameChatOverviewMixin:RefreshOpenConversation(playerName)
    if(playerName == self.name) then
        dataProvider:Flush()

        self:SetMessages(playerName)

    end
end

function AppFrameChatOverviewMixin:CompareAndSetDateForHeader(date)
    local today = C_DateAndTime.GetCurrentCalendarTime()

    if(not CalendarUtil.AreDatesEqual(today, date)) then
        local weekDay = CALENDAR_WEEKDAY_NAMES[date.weekday]
        local month = CALENDAR_FULLDATE_MONTH_NAMES[date.month]
        self.Header.Time:SetText(LAST_ONLINE_COLON .. " " .. format("%s, %d %s %d, %02d:%02d", weekDay, date.monthDay, month, date.year, date.hour, date.minute))

    else
        
        self.Header.Time:SetText(LAST_ONLINE_COLON .. " " .. format("%02d:%02d", date.hour, date.minute))

    end

    self.Header.Time:SetTextColor(WHITE_FONT_COLOR:GetRGBA())
end

function AppFrameChatOverviewMixin:OpenConversation(playerName)
    self:Show()
    self:CloseCurrentConversation()

    self.name = playerName
    self.hasOpenConversation = true
    
    local logs = MW_ChatLogs[playerName]

    if(logs) then
        if(logs.unitGUID) then
            local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(logs.unitGUID)

            if(englishClass) then
                self.Header.Picture:SetColorTexture(C_ClassColor.GetClassColor(englishClass):GetRGBA())

            end
        end

        self.Header.Name:SetText(logs.name)

        if(logs.lastOnline.monthDay > 0) then
            self:CompareAndSetDateForHeader(logs.lastOnline)

        else
            local lastMessage = logs.messages[#logs.messages]

            if(lastMessage and lastMessage.date) then
                self:CompareAndSetDateForHeader(lastMessage.date)

            else
                self.Header.Time:SetText(LAST_ONLINE_COLON .. " " .. UNKNOWN)

            end
        end
    end

    self:SetMessages(playerName)

    self.Header:Show()
    self.EditBoxContainer:Show()
end

function AppFrameChatOverviewMixin:UpdateWhoData(hasData, isOnline)
    self:CancelWhoTimer()
    self.Header.LoadingSpinner:Hide()

    if(hasData) then
        if(isOnline) then
            self.Header.Time:SetText(FRIENDS_LIST_ONLINE)
            self.Header.Time:SetTextColor(GREEN_FONT_COLOR:GetRGBA())

            MW_ChatLogs[self.name].lastOnline = C_DateAndTime.GetCurrentCalendarTime()

        else
            self.Header.Time:SetText(FRIENDS_LIST_OFFLINE)
            self.Header.Time:SetTextColor(RED_FONT_COLOR:GetRGBA())

        end
    else
        self.Header.Time:SetText(ERR_HOUSING_RESULT_TOO_MANY_REQUESTS)
        self.Header.Time:SetTextColor(YELLOW_FONT_COLOR:GetRGBA())

    end
end