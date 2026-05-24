local addonName, mw = ...

AppFrameConversationButtonMixin = {}

local MAX_NUMBER_FRIENDS = 100
local MAX_NUMBER_IGNORES = 50

function AppFrameConversationButtonMixin:OnLoad()

end

function AppFrameConversationButtonMixin:ShowNewMessages(numOfMessages)
    self.NewMessages:Show()
    self.NumberOfNewMessages:Show()

    if(numOfMessages) then
        self.NumberOfNewMessages:SetText(numOfMessages > 9 and "9+" or numOfMessages)

    end
end

function AppFrameConversationButtonMixin:HideNewMessages()
    self.NewMessages:Hide()
    self.NumberOfNewMessages:Hide()

end

function AppFrameConversationButtonMixin:Refresh()
    local data = self:GetData()

    if(data.picture) then
        if(data.picture.atlas) then
            self.Picture:SetAtas(data.picture.atlas)
            
        elseif(data.picture.filePath) then
            self.Picture:SetTexture(data.picture.filePath)

        end

    elseif(data.unitGUID) then
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(data.unitGUID)

        if(englishClass) then
            self.Picture:SetColorTexture(C_ClassColor.GetClassColor(englishClass):GetRGBA())

        else
            self.Picture:SetColorTexture(WHITE_FONT_COLOR:GetRGBA())

        end
    else
        self.Picture:SetColorTexture(WHITE_FONT_COLOR:GetRGBA())

    end

    self.Name:SetText(data.name)
    self.LastMessage:SetText(data.message)

    if(data.date) then
        self.Time:SetText(format("%02d:%02d", data.date.hour, data.date.minute))

    end

    if(data.numOfUnreadMessages) then
        if(data.numOfUnreadMessages > 0) then
            self:ShowNewMessages(data.numOfUnreadMessages)

        else
            self:HideNewMessages()

        end
    end

    self.name = data.name
end

function AppFrameConversationButtonMixin:CheckIfInSameCommunity(playerName)
    local allClubs = C_Club.GetSubscribedClubs()


end

function AppFrameConversationButtonMixin:IsPlayerInGroup()
    for i = 1, 40, 1 do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)

        local fullName, playerName, realm = MythicWhispers.CreateFullNameValuesFrom("unitName", name)
    
        if(fullName) then
            if(fullName == self.name) then
                return true

            end
        end
    end

    return false
end

function AppFrameConversationButtonMixin:InCallWithPlayer()
    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        for k, v in ipairs(channel.members) do
            local name = C_VoiceChat.GetMemberName(v.memberID, channelID)
            local guid = C_VoiceChat.GetMemberGUID(v.memberID, channelID)
            local localizedClass, englishClass, localizedRace, englishRace, sex, _, realmName = GetPlayerInfoByGUID(guid)

            local fullName, playerName, realm = MythicWhispers.CreateFullNameValuesFrom("unitName", name .. (realmName and realmName ~= "" and ("-" .. realmName) or ""))

            if(fullName == self.name) then
                return true

            end
        end
    end

    return false
end

function AppFrameConversationButtonMixin:OnClick(...)
    if(... == "LeftButton") then
        EventRegistry:TriggerEvent("MythicWhispers.OpenConversation", self.name)
        self:HideNewMessages()

    elseif(... == "RightButton") then
        local currentMenu = MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(BINDING_HEADER_CHAT);
			rootDescription:SetTag("MW_CONVERSATIONBUTTON")

			rootDescription:CreateButton(DELETE, function()
                EventRegistry:TriggerEvent("MythicWhispers.DeleteConversation", self.name)
                
            end)

            local friendInfo = C_FriendList.GetFriendInfo(self.name)

            if(friendInfo) then
                if(not C_FriendList.IsFriend(friendInfo.guid)) then
                    rootDescription:CreateButton(ADD_FRIEND .. " - " .. C_FriendList.GetNumFriends() .. "/" .. MAX_NUMBER_FRIENDS, function()
                        C_FriendList.AddFriend(self.name)
                        
                    end)
                end

                if(not C_FriendList.IsIgnoredByGuid(friendInfo.guid)) then
                    rootDescription:CreateButton(IGNORE_PLAYER .. " - " .. C_FriendList.GetNumIgnores() .. "/" .. MAX_NUMBER_IGNORES, function()
                        C_FriendList.AddIgnore(self.name)
                        
                    end)
                end
            end

            local playerInGroup = self:IsPlayerInGroup()
            local inCallWithPlayer = self:InCallWithPlayer()

            if(inCallWithPlayer) then
                rootDescription:CreateButton(VOICE_CHAT_LEAVE, function()
                    local channelID = C_VoiceChat.GetActiveChannelID()

                    if(channelID) then
                        C_VoiceChat.LeaveChannel(channelID)

                    end

                end)

            else
                local partyRaidButton = rootDescription:CreateButton("Call via party/raid chat", function()
                    --[[local player1 = UnitName("player")
                    local _, player2 = createFullNameValuesFrom("unitName", self.name)
                    local channelName = "MWCHAT"
                    --print(channelName)
                    --local zoneChannel, _ = JoinPermanentChannel("MWVoiceChannelsXX", "123123", 3, 1);
                    local allClubs = C_Club.GetSubscribedClubs()
                    local streams = C_Club.GetStreams(allClubs[2].clubId)

                    print(allClubs[2].clubId, streams[1].streamId)
                    C_Club.CreateStream(214472962, "MWT2", "VOICE", false)
                    C_VoiceChat.RequestJoinAndActivateCommunityStreamChannel(allClubs[2].clubId, streams[1].streamId)
                    C_VoiceChat.RequestJoinAndActivateCommunityStreamChannel(214472962, 1)

                    --Enum.ChatChannelType.Communities

                    local status = C_VoiceChat.CreateChannel("MWVoiceChannels1")

                    if(status ~= 0) then
                        print(status, Voice_GetGameErrorFromStatusCode(status), Voice_GetGameErrorStringFromStatusCode(status))

                    else
                        print("ROGER")

                    end
                    ]]
        
                    --local allClubs = C_Club.GetSubscribedClubs()

                    --local streamId

                    --local streams = C_Club.GetStreams(allClubs[2].clubId)
                    EventRegistry:TriggerEvent("MythicWhispers.HandleJoinRequest", IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and 3 or 2)

                end)
                partyRaidButton:SetEnabled(C_VoiceChat.CanPlayerUseVoiceChat() and C_VoiceChat.IsLoggedIn() and playerInGroup)

                if(IsInGroup() and not playerInGroup) then
                    partyRaidButton:SetTooltip(function(tooltip, elementDescription)
                        GameTooltip_SetTitle(tooltip, QUICK_JOIN_ALREADY_IN_PARTY);

                    end)
                end

                local communityTitleButton = rootDescription:CreateButton("Call via community chat")

                local hasCommunityWithCharacter = false
                
                for k, v in ipairs(C_Club.GetSubscribedClubs()) do
                    local members = C_Club.GetClubMembers(v.clubId)

                    for x, y in ipairs(members) do
                        local memberInfo = C_Club.GetMemberInfo(v.clubId, y)

                        local fullName = MythicWhispers.CreateFullNameValuesFrom("unitName", memberInfo.name)

                        if(fullName == self.name) then
                            hasCommunityWithCharacter = true
                            local streams = C_Club.GetStreams(v.clubId)

                            local communityButton = communityTitleButton:CreateButton(v.name .. (v.clubId == C_Club.GetGuildClubId() and AUTOCOMPLETE_LABEL_GUILD or ""))

                            for a, b in ipairs(streams) do
                                local streamButton = communityButton:CreateButton(b.name, function(data)
                                    EventRegistry:TriggerEvent("MythicWhispers.HandleJoinRequest", data.clubId, data.streamId)
                                
                                end, {clubId = v.clubId, streamId = b.streamId})
                            end
                        end
                    end
                end

                communityTitleButton:SetEnabled(hasCommunityWithCharacter)
            end

		end)

		if(currentMenu) then
			currentMenu:SetPoint("TOPLEFT", self, "TOPRIGHT")

		end
    end
end



-- BACKDROP_TEXT_PANEL_0_16
-- BACKDROP_CHARACTER_CREATE_TOOLTIP_32_32
-- BACKDROP_TOAST_12_12


local BACKDROP_TEXT_PANEL_WITH_BG = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
	edgeSize = 16,
	insets = { left = 3, right = 2, top = 1, bottom = 3 },
}


local BACKDROP_TOAST = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 3},
}

local BACKDROP_TUTORIAL = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
};



AppFrameConversationMessageMixin = {}

function AppFrameConversationMessageMixin:OnClick(...)
    if(... == "LeftButton") then

    elseif(... == "RightButton") then
        local currentMenu = MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle();
			rootDescription:SetTag("MW_CONVERSATIONBUTTON")

			rootDescription:CreateButton(DELETE, function()
                EventRegistry:TriggerEvent("MythicWhispers.DeleteConversation", self.name)
                
            end)
        end)
    end
end

function AppFrameConversationMessageMixin:Refresh()
    local data = self:GetData()

    self.sender = data.sender

    self.Message:SetText(data.message)
    self.Time:SetText(format("%02d:%02d", data.date.hour, data.date.minute))

    self:SetBackdrop(BACKDROP_TUTORIAL)
    self:SetBackdropBorderColor(1, 1, 1, 1)

    self.Time:ClearAllPoints()

    local messageFromPlayer = data.sender == "player"

    if(messageFromPlayer) then
        --self.Background:SetColorTexture(0.65, 1, 0.65, 1)
        self:SetBackdropColor(0.65, 1, 0.65, 1)
        --self.Checkmark:SetDesaturated(not data.viewed)
        self.Time:SetPoint("BOTTOMRIGHT", -17, 6)

    else
        --self.Background:SetColorTexture(1, 1, 1, 1)
        self:SetBackdropColor(1, 1, 1, 1)
        self.Time:SetPoint("BOTTOMRIGHT", -7, 6)

    end

    self.Checkmark:SetShown(messageFromPlayer)
    self.BlueCircle:SetShown(messageFromPlayer and data.read)
end




AppFrameNewConversationButtonMixin = {}

function AppFrameNewConversationButtonMixin:OnLoad()

end

function AppFrameNewConversationButtonMixin:Refresh()

end



AppFrameConversationButtonVoiceChatMixin = {}

function AppFrameConversationButtonVoiceChatMixin:SetChatType(type)
    self:UnregisterAllMessageGroups()

    self:AddMessageGroup(type)

    self.Name:SetText(strlower(type):gsub("^%l", string.upper) .. " " .. VOICE_CHAT)

end

function AppFrameConversationButtonVoiceChatMixin:OnLoad()
    self.messageTypeList = {}
    self.LastMessage:SetText()
    EventRegistry:RegisterCallback("MythicWhispers.ChatTypeChanged", self.SetChatType, self)

end

function AppFrameConversationButtonVoiceChatMixin:OnClick(...)
    if(... == "LeftButton") then
        EventRegistry:TriggerEvent("MythicWhispers.OpenVoiceChatRoom")

    else
        local currentMenu = MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(VOICE_CHAT);
			rootDescription:SetTag("MW_CONVERSATIONBUTTON_VOICECHAT")

            rootDescription:CreateButton(VOICE_CHAT_LEAVE, function()
                local channelID = C_VoiceChat.GetActiveChannelID()

                if(channelID) then
                    C_VoiceChat.LeaveChannel(channelID)

                end

            end)
        end)

    end
end

function AppFrameConversationButtonVoiceChatMixin:OnEvent(event, ...)
    print(event)

end

function AppFrameConversationButtonVoiceChatMixin:AddMessageGroup(group)
	local info = ChatTypeGroup[group];
	if ( info ) then
		tinsert(self.messageTypeList, group);
		for index, value in pairs(info) do
			self:RegisterEvent(value);

		end
	end
end

function AppFrameConversationButtonVoiceChatMixin:UnregisterAllMessageGroups()
	for index, value in pairs(self.messageTypeList) do
		for eventIndex, eventValue in pairs(ChatTypeGroup[value]) do
			self:UnregisterEvent(eventValue);
		end
	end

	self.messageTypeList = {};
end