AppFrameChatListMixin = {}

local dataProvider = CreateDataProvider()

function AppFrameChatListMixin:OnLoad()
    local view = CreateScrollBoxListLinearView();

    function MW_CreateConversation(frame, data)
        if(data.template == "MW_AppFrameConversationButton" or data.template == "MW_AppFrameNewConversationButton") then
            frame:Refresh()

        --elseif(data.template == "MW_AppFrameConversationButtonVoiceChat") then
            --frame:Refresh()

        end
    end

    view:SetElementFactory(function(factory, data)
        local template = data.template
        factory(template, MW_CreateConversation)

    end)
    view:SetPadding(2, 2, 2, 2, 2);

	local scrollBoxAnchorsWithBar = {
		CreateAnchor(self.ScrollBox:GetPointByName("TOPLEFT")),
		CreateAnchor("BOTTOMRIGHT", -18, 0);
	}

	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", 0, 0);
	}

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    self.ScrollBox:SetDataProvider(dataProvider);

	EventRegistry:RegisterCallback("MythicWhispers.OpenConversation", self.RefreshConversationButtons, self);
	EventRegistry:RegisterCallback("MythicWhispers.RefreshConversation", self.RefreshConversationButtons, self);

    self:SetScript("OnEvent", function(selfFrame, event, ...)
        if(event == "VOICE_CHAT_CHANNEL_ACTIVATED" or event == "VOICE_CHAT_CHANNEL_DEACTIVATED") then
            self:RefreshConversationButtons()

        end
    end)
    self:RegisterEvent("VOICE_CHAT_CHANNEL_ACTIVATED")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_DEACTIVATED")

    self.Tabs = {
        [1] = self.Tab1,
        [2] = self.Tab2
    }
    PanelTemplates_SetNumTabs(self, 2)
    --PanelTemplates_SetTabEnabled(self, 8, false);
    PanelTemplates_SetTab(self, 1)
end

function AppFrameChatListMixin:SetWidthViaParentWidth(parentWidth)
    self:SetWidth(parentWidth * WIDTH_SCALE)
    
end

function AppFrameChatListMixin:SetDataCallback(data)
    return function()
        self:GetParent().ChatOverview:SetData(data)
    end

end

function AppFrameChatListMixin:HasLogs()
    for _ in pairs(MW_ChatLogs) do
        return true

    end

    return false
end

function AppFrameChatListMixin:RefreshConversationButtons()
    dataProvider:Flush()

    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        if(channel and channel.isActive) then
            dataProvider:Insert({
                template = "MW_AppFrameConversationButtonVoiceChat",
            })

        end
    end

    if(MW_ChatLogs and self:HasLogs()) then
        local orderedList = {}

        for k, v in pairs(MW_ChatLogs) do
            local tbl = {
                template = "MW_AppFrameConversationButton",
                unitGUID = v.unitGUID,
                name = v.name,
                picture = v.picture,
                numOfUnreadMessages = v.numOfUnreadMessages
            }

            local lastMessage = v.messages[#v.messages]

            if(lastMessage) then
                tbl.sender = lastMessage.sender
                tbl.message = lastMessage.message
                tbl.date = lastMessage.date
                tbl.timestamp = lastMessage.timestamp

            end

            tinsert(orderedList, tbl)
        end

        table.sort(orderedList, function(k1, k2)
            return k1.timestamp > k2.timestamp

        end)

        for k, v in ipairs(orderedList) do
            dataProvider:Insert(v)
        end

    else
         dataProvider:Insert({
            template = "MW_AppFrameNewConversationButton",
        })

    end
end

function AppFrameChatListMixin:RefreshFriendsButtons()
    dataProvider:Flush()

    C_FriendList.ShowFriends()

    local numBNetTotal, numBNetOnline, numBNetFavorite, numBNetFavoriteOnline = BNGetNumFriends()

    local bnetList = {}

    for i = 1, numBNetTotal, 1 do
        local info = C_BattleNet.GetFriendGameAccountInfo(i, 1)

        if(info) then
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)

            local tbl = {
                index = i,
                clientProgram = info.clientProgram,
                unitGUID = info.playerGuid,
                name = info.characterName or accountInfo.accountName,
            }

            tinsert(bnetList, tbl)
        end
    end

    table.sort(bnetList, function(a, b)
        -- 1. Sort by isOnline (true comes before false)
        if a.isOnline ~= b.isOnline then
            return a.isOnline and not b.isOnline
        end

        -- 2. If isOnline is the same, sort by clientProgram (A-Z)
        if a.clientProgram == BNET_CLIENT_WOW ~= b.clientProgram == BNET_CLIENT_WOW then
            return a.clientProgram == BNET_CLIENT_WOW < b.clientProgram == BNET_CLIENT_WOW
        end

        -- 3. If both above are the same, sort by name (A-Z)
        return a.name < b.name
    end)

    for k, v in ipairs(bnetList) do
        dataProvider:Insert({
            template = "MW_AppFrameConversationButton",
            unitGUID = v.unitGUID,
            name = v.name,
        })

    end

    for i = 1, C_FriendList.GetNumFriends(), 1 do
        local info = C_FriendList.GetFriendInfoByIndex(i)

    end
end

function AppFrameChatListMixin:OnShow()
    self:RefreshConversationButtons()

    if(self.selectedTab == 2) then
        self:RefreshFriendsButtons()

    end
end