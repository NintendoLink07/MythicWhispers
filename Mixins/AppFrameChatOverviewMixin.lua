AppFrameChatOverviewMixin = CreateFromMixins(CallbackRegistryMixin)

local dataProvider = CreateDataProvider()

local WIDTH_SCALE = 0.8
local LINE_HEIGHT = 12
local MAX_NUM_CHARACTERS_PER_LINE = 26

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

    end
    
	return frame:GetHeight();
end

function AppFrameChatOverviewMixin:HasOpenConversation()
    return self.hasOpenConversation

end

function AppFrameChatOverviewMixin:OnLoad()
    self.hasOpenConversation = false

    CallbackRegistryMixin.OnLoad(self)
	EventRegistry:RegisterCallback("MythicWhispers.OpenConversation", self.OpenConversation, self);

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
    view:SetElementExtentCalculator(function(dataIndex, elementData)
        local stringWidth = strlen(elementData.message)

        for i = 1, 100, 1 do
            if(stringWidth < i * MAX_NUM_CHARACTERS_PER_LINE) then
                return i * LINE_HEIGHT + 10;

            end
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
    
	local scrollBoxAnchorsWithBar = {
		CreateAnchor("TOPLEFT", self.Header, "BOTTOMLEFT", 0, 0),
		CreateAnchor("BOTTOMRIGHT", self.EditBox, "TOPRIGHT", -18, 0);
	}

	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", self.EditBox, "TOPRIGHT", 0, 0);
	}

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    self.ScrollBox:SetDataProvider(dataProvider);

	local defaultLanguage, defaultLanguageId = GetDefaultLanguage();

    self.EditBox.ChatBox:SetScript("OnEnterPressed", function(selfBox, ...)
        if(self.name) then
            C_ChatInfo.SendChatMessage(selfBox:GetText(), "WHISPER", defaultLanguageId, self.name)
            selfBox:SetText("")
            selfBox:ClearFocus()
        end
    end)
end

function AppFrameChatOverviewMixin:SetWidthViaParentWidth(parentWidth)
    self:SetWidth(parentWidth * WIDTH_SCALE)
    
end

function AppFrameChatOverviewMixin:SetMessages(playerName)
    local logs = MW_ChatLogs[playerName]
    local messages = logs.messages

    local numOfMessages = #messages

    for i = max(1, numOfMessages - 200), numOfMessages, 1 do
        local v = messages[i]

        if(v.viewed == false) then
            logs.numOfUnreadMessages = logs.numOfUnreadMessages - 1
            v.viewed = true

        end

        dataProvider:Insert({
            template = "MW_AppFrameConversationMessage",
            sender= v.sender,
            message = v.message,
            date = v.date,
        })

    end
end

function AppFrameChatOverviewMixin:Refresh()
    dataProvider:Flush()

    local name = self.name

    if(name) then
        self.Header:SetData(name)
        self:SetMessages(name)

        self.ScrollBox:ScrollToEnd()
    end
end

function AppFrameChatOverviewMixin:OpenConversation(name)
    self.name = name
    self.hasOpenConversation = true
    self.Header:Show()
    self.EditBox:Show()

    self:Refresh()
end

function AppFrameChatOverviewMixin:CloseCurrentConversation()
    self.name = nil
    self.hasOpenConversation = false
    self.Header:Hide()
    self.EditBox:Hide()

    self:Refresh()
end



AppFrameChatOverviewHeaderMixin = {}

function AppFrameChatOverviewHeaderMixin:SetData(playerName)
    local logs = MW_ChatLogs[playerName]

    local messages = logs.messages[#logs.messages]

    if(logs.unitGUID) then
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(logs.unitGUID)

        if(englishClass) then
            self.Picture:SetColorTexture(C_ClassColor.GetClassColor(englishClass):GetRGBA())

        end
    end

    self.Name:SetText(logs.name)

    local weekDay = CALENDAR_WEEKDAY_NAMES[messages.date.weekday]
    local month = CALENDAR_FULLDATE_MONTH_NAMES[messages.date.month]
    self.Time:SetText(LAST_ONLINE_COLON .. " " .. format("%02d:%02d", messages.date.hour, messages.date.minute))
    self.Time:SetTextColor(WHITE_FONT_COLOR:GetRGBA())

    self.CheckStatusButton:SetScript("OnClick", function(selfButton, ...)
        C_FriendList.SetWhoToUi(false)
        C_FriendList.SendWho("n-"..playerName, 1)
    
    end)
end

function AppFrameChatOverviewHeaderMixin:CloseConversation()
    self:GetParent():CloseCurrentConversation()

end