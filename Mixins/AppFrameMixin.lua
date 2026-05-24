local addonName, mw = ...

local LEFT_SIDE_WIDTH_SCALE = 0.2
local RIGHT_SIDE_WIDTH_SCALE = 0.8

local requestPending

local voiceChatStatusToGameError =
{
	[Enum.VoiceChatStatusCode.Success] = SUPPRESS_ERROR_MESSAGE,
	[Enum.VoiceChatStatusCode.OperationPending] = DISPLAY_BASIC_ERROR_ONLY,
	[Enum.VoiceChatStatusCode.TooManyRequests] = LE_GAME_ERR_VOICE_CHAT_TOO_MANY_REQUESTS,

	[Enum.VoiceChatStatusCode.ClientAlreadyLoggedIn] = DISPLAY_BASIC_ERROR_ONLY,
	[Enum.VoiceChatStatusCode.ChannelNameTooShort] = LE_GAME_ERR_VOICE_CHAT_CHANNEL_NAME_TOO_SHORT,
	[Enum.VoiceChatStatusCode.ChannelNameTooLong] = LE_GAME_ERR_VOICE_CHAT_CHANNEL_NAME_TOO_LONG,
	[Enum.VoiceChatStatusCode.ChannelAlreadyExists] = LE_GAME_ERR_VOICE_CHAT_CHANNEL_ALREADY_EXISTS,
	[Enum.VoiceChatStatusCode.AlreadyInChannel] = DISPLAY_BASIC_ERROR_ONLY,
	[Enum.VoiceChatStatusCode.TargetNotFound] = LE_GAME_ERR_VOICE_CHAT_TARGET_NOT_FOUND,
	[Enum.VoiceChatStatusCode.Failure] = RESPONSE_FAILURE,
	[Enum.VoiceChatStatusCode.ServiceLost] = LE_GAME_ERR_VOICE_CHAT_SERVICE_LOST,
	[Enum.VoiceChatStatusCode.UnableToLaunchProxy] = LE_GAME_ERR_VOICE_CHAT_GENERIC_UNABLE_TO_CONNECT,
	[Enum.VoiceChatStatusCode.ProxyConnectionTimeOut] = LE_GAME_ERR_VOICE_CHAT_SERVICE_LOST,
	[Enum.VoiceChatStatusCode.ProxyConnectionUnableToConnect] = LE_GAME_ERR_VOICE_CHAT_GENERIC_UNABLE_TO_CONNECT,
	[Enum.VoiceChatStatusCode.ProxyConnectionUnexpectedDisconnect] = LE_GAME_ERR_VOICE_CHAT_SERVICE_LOST,
	[Enum.VoiceChatStatusCode.Disabled] = LE_GAME_ERR_VOICE_CHAT_DISABLED,

	[Enum.VoiceChatStatusCode.PlayerSilenced] = LE_GAME_ERR_VOICE_CHAT_PLAYER_SILENCED,
	[Enum.VoiceChatStatusCode.PlayerVoiceChatParentalDisabled] = LE_GAME_ERR_VOICE_CHAT_PARENTAL_DISABLE_ALL,
};

AppFrameMixin = {}

mw.C = {
    STANDARD_FILE_PATH = "Interface/Addons/" .. addonName .. "/res"
}

local MULTIPLICATOR = 0.8

local BACKDROP_INFO_WITH_BG = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1
}

local BACKDROP_INFO = {
    edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1
}

local EXPANSIONS = {
	[0] = {name = "Classic", background = "vanilla-bg-1", logo = GetExpansionDisplayInfo(0).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/0.png"},
	[1] = {name = "The Burning Crusade", background = "tbc-bg-1", logo = GetExpansionDisplayInfo(1).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/1.png"},
	[2] = {name = "Wrath of the Lich King", background = "wotlk-bg-1", logo = GetExpansionDisplayInfo(2).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/2.png"},
	[3] = {name = "Cataclysm", background = "cata-bg-1", logo = GetExpansionDisplayInfo(3).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/3.png"},
	[4] = {name = "Mists of Pandaria", background = "mop-bg-1", logo = GetExpansionDisplayInfo(4).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/4.png"},
	[5] = {name = "Warlords of Draenor", background = "wod-bg-1", logo = GetExpansionDisplayInfo(5).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/5.png"},
	[6] = {name = "Legion", background = "legion-bg-1", logo = GetExpansionDisplayInfo(6).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/6.png"},
	[7] = {name = "Battle for Azeroth", background = "bfa-bg-1", logo = GetExpansionDisplayInfo(7).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/7.png"},
	[8] = {name = "Shadowlands", background = "sl-bg-1", logo = GetExpansionDisplayInfo(8).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/8.png"},
	[9] = {name = "Dragonflight", background = "df-bg-1", logo = GetExpansionDisplayInfo(9).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/9.png"},
	[10] = {name = "The War Within", background = "tww-bg-1", logo = GetExpansionDisplayInfo(10).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/10.png", borderColor = CreateColor(0.35, 0.22, 0.1, 1)},
	[11] = {name = "Midnight", background = "mn-bg-1", logo = GetExpansionDisplayInfo(11).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/11.png", borderColor = CreateColor(0, 0.12, 0.25, 1)},
}

function AppFrameMixin:ClearPalette()
    self.TitleBar:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.TitleBar:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())
    self.TitleBar.Background:SetTexture(nil)

    self.ChatList:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.ChatList:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())
    self.ChatList.Background:SetTexture(nil)

    self.ChatOverview:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.ChatOverview:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())
    self.ChatOverview.Background:SetTexture(nil)

    self.VoiceChatRoom:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.VoiceChatRoom:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())
    self.VoiceChatRoom.Background:SetTexture(nil)

    self.ChatOverview.Header:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.ChatOverview.Header:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())

    self.ChatOverview.EditBoxContainer:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.ChatOverview.EditBoxContainer:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())

    self.VoiceChatRoom.ChatContainer:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.VoiceChatRoom.ChatContainer:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())

    self.VoiceChatRoom.ChatContainer.EditBoxContainer:SetBackdrop(BACKDROP_INFO_WITH_BG)
    self.VoiceChatRoom.ChatContainer.EditBoxContainer:SetBackdropBorderColor(GRAY_FONT_COLOR:GetRGBA())

end

function AppFrameMixin:SetExpansionPalette(expansion)
    local expansionData = EXPANSIONS[expansion]

    if(expansionData) then
        local background = EXPANSIONS[expansion].background
        local filePath = mw.C.STANDARD_FILE_PATH .. "/backgrounds/" .. background .. ".png"

        self.TitleBar:SetBackdrop(BACKDROP_INFO)
        self.TitleBar:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.TitleBar.Background:SetTexture(filePath)
        self.TitleBar.Background:SetTexCoord(0, 1, 0, 0.05)

        self.ChatList:SetBackdrop(BACKDROP_INFO)
        self.ChatList:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.ChatList.Background:SetTexture(filePath)
        self.ChatList.Background:SetTexCoord(0, 0.2, 0.055, 1)

        self.ChatOverview:SetBackdrop(BACKDROP_INFO)
        self.ChatOverview:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.ChatOverview.Background:SetTexture(filePath)
        self.ChatOverview.Background:SetTexCoord(0.2, 1, 0.055, 1)

        self.VoiceChatRoom:SetBackdrop(BACKDROP_INFO)
        self.VoiceChatRoom:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.VoiceChatRoom.Background:SetTexture(filePath)
        self.VoiceChatRoom.Background:SetTexCoord(0.2, 1, 0.055, 1)

        self.ChatOverview.Header:SetBackdrop(BACKDROP_INFO)
        self.ChatOverview.Header:SetBackdropColor(0, 0, 0, 0)
        self.ChatOverview.Header:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())

        self.ChatOverview.EditBoxContainer:SetBackdrop(BACKDROP_INFO)
        self.ChatOverview.EditBoxContainer:SetBackdropColor(0, 0, 0, 0)
        self.ChatOverview.EditBoxContainer:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())

        self.VoiceChatRoom.ChatContainer:SetBackdrop(BACKDROP_INFO)
        self.VoiceChatRoom.ChatContainer:SetBackdropColor(0, 0, 0, 0)
        self.VoiceChatRoom.ChatContainer:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())

        self.VoiceChatRoom.ChatContainer.EditBoxContainer:SetBackdrop(BACKDROP_INFO)
        self.VoiceChatRoom.ChatContainer.EditBoxContainer:SetBackdropColor(0, 0, 0, 0)
        self.VoiceChatRoom.ChatContainer.EditBoxContainer:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
    end
end

function AppFrameMixin:CreatePlayerLogs(playerName)
    MW_ChatLogs[playerName] = {
        picture = nil,
        name = playerName,
        numOfUnreadMessages = 0,
        lastOnline = {monthDay = 0},
        messages = {},
        scheduledStatusMessages = {},
    }
end

function AppFrameMixin:CreateConversation(playerName, guid)
    if(playerName) then
        local logs = MW_ChatLogs[playerName]

        if(not logs) then
            self:CreatePlayerLogs(playerName)

            logs = MW_ChatLogs[playerName]
        end

        if(not logs.scheduledStatusMessages) then
            logs.scheduledStatusMessages = {}

        end

        if(guid) then
            logs.unitGUID = guid

        end
    end
end

function AppFrameMixin:AddLog(playerName, text, sender)
    if(playerName) then
        local logs = MW_ChatLogs[playerName]
        local chatOpen = self.ChatOverview:GetOpenConversationName() == playerName
        local currentDate = C_DateAndTime.GetCurrentCalendarTime()

        if(sender == "character") then
            if(not chatOpen) then
                logs.numOfUnreadMessages = logs.numOfUnreadMessages + 1

            else
                EventRegistry:TriggerEvent("MythicWhispers.SendMessageRead", playerName, currentDate, text)

            end

            logs.lastOnline = currentDate

        end
        
        tinsert(logs.messages, {
            sender = sender,
            message = text,
            date = currentDate,
            viewed = chatOpen or sender == "player",
            timestamp = GetServerTime(),
        })
    end
end

function AppFrameMixin:DeleteConversation(playerName)
    if(playerName) then
        MW_ChatLogs[playerName] = nil

        if(playerName == self.ChatOverview:GetOpenConversationName()) then
            self.ChatOverview:CloseCurrentConversation()

        end

        self.ChatList:RefreshConversationButtons()
    end
end

function AppFrameMixin:SetConversationToAllRead(playerName)
    if(playerName) then
        MW_ChatLogs[playerName].numOfUnreadMessages = 0

        if(playerName == self.ChatOverview:GetOpenConversationName()) then
            self.ChatOverview:CloseCurrentConversation()

        end

        self.ChatList:Refresh()
    end
end

function AppFrameMixin:SetVoiceChatCallStatusColor(channelID)
    if(channelID) then
        local r, g, b = Voice_GetVoiceChannelNotificationColor(channelID)
        self.TitleBar.VoiceChatCallStatus.ColoredTexture:SetColorTexture(r, g, b, 1)

    else
        self.TitleBar.VoiceChatCallStatus.ColoredTexture:SetColorTexture(0.3, 0.3, 0.3, 0.7)

    end
end

function AppFrameMixin:RefreshVoiceChatServiceStatus()
    if(C_VoiceChat.IsLoggedIn()) then
        self.TitleBar.VoiceChatServiceStatus.ColoredTexture:SetColorTexture(0, 1, 0, 1)

    else
        self.TitleBar.VoiceChatServiceStatus.ColoredTexture:SetColorTexture(1, 0, 0, 1)

    end
end

function AppFrameMixin:HandleJoinRequest(id1, id2)
    if(not C_VoiceChat.IsLoggedIn()) then
        C_VoiceChat.Login()

        requestPending = {id1 = id1, id2 = id2}
        return
    end

    local isCommunity = id2 ~= nil

    if(isCommunity) then
        C_VoiceChat.RequestJoinAndActivateCommunityStreamChannel(id1, id2)
        
    else
        C_VoiceChat.RequestJoinChannelByChannelType(id1)
        
    end

    requestPending = {}
end

function AppFrameMixin:CheckServiceStatus(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")

    if(C_VoiceChat.IsLoggedIn()) then
        GameTooltip:SetText(format(VOICE_CHAT_CHANNEL_ACTIVE_TOOLTIP, BATTLENET_OPTIONS_LABEL))

    else
        local statusCode = C_VoiceChat.GetCurrentVoiceChatConnectionStatusCode()
        local status = Voice_GetGameErrorStringFromStatusCode(statusCode)

        if(status) then
            GameTooltip:SetText(BINDING_HEADER_VOICE_CHAT .. ": " .. status)
        
        elseif(not C_VoiceChat.CanPlayerUseVoiceChat()) then
            GameTooltip:SetText(ERR_VOICE_CHAT_SERVICE_UNABLE_TO_CONNECT)

        end

    end

    GameTooltip:Show()

end

function AppFrameMixin:CheckCallStatus(frame)
    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)
        
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(Voice_FormatChannelNotification(channel, Voice_GetChannelActivatedNotification(channel)))
        GameTooltip:Show()
    end
end

function AppFrameMixin:SendMuteStatusUpdate()
    local tbl = {
        event = "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED",
        muted = C_VoiceChat.IsMuted()
    }

    local status = C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), MythicWhispers:GetChatType())

end

function AppFrameMixin:RequestMuteStatusUpdate()
    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        if(channel and channel.isActive) then
            local tbl = {
                event = "VOICE_CHAT_CHANNEL_TRANSMIT_REQUEST",
            }
            local status = C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), MythicWhispers:GetChatType())

        end
    end
end

function AppFrameMixin:ScheduleAddonMessageForReadMessages(sender, tbl)
    local logs = MW_ChatLogs[sender]

    tinsert(logs.scheduledStatusMessages, tbl)

end

function AppFrameMixin:SendMessageRead(sender, date, message)
    if(sender and date) then
        local tbl = {
            event = "TEXT_MESSAGE_READ",
            date = date,
            hash = MythicWhispers.WriteCBOR(message)

        }

        local status = C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), "WHISPER", sender)

        if(status == Enum.SendAddonMessageResult.TargetOffline) then
            self:ScheduleAddonMessageForReadMessages()

        end
    end
end

--[[function AppFrameMixin:SendMessageReadOverChannel(sender, date)
    if(sender and date) then
        local chatName = "MYTHICWHISPERSVALUESCHAT"

        JoinPermanentChannel(chatName, nil, nil, 0)

        local channelID

        for i = 1, 100, 1 do
	        local name, header, _, channelNumber, count, active, category, channelType = GetChannelDisplayInfo(i);

            if(name == chatName) then
                channelID = channelNumber
                break

            end
        end

        if(channelID) then
            local tbl = {
                event = "TEXT_MESSAGE_READ",
                date = date,
                sender = sender
            }
            local result = C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), "CHANNEL", channelID)

            print("SENT!", result)
        end
    end
end]]

function AppFrameMixin:SetMessageRead(tbl)
    local sender, date, hash = tbl.sender, tbl.date, tbl.hash
    local logs = MW_ChatLogs[sender]

    for k, v in MythicWhispers.rpairs(logs.messages) do
        if(not v.read and C_DateAndTime.CompareCalendarTime(date, v.date) == 0 and MythicWhispers.ReadCBOR(hash) == v.message) then
            v.read = true
            break
        end
    end
end

function AppFrameMixin:OnLoad()
    self:SetSize(GetScreenWidth() * MULTIPLICATOR, GetScreenHeight() * MULTIPLICATOR)

    self.ChatList:SetWidth(self:GetWidth() * LEFT_SIDE_WIDTH_SCALE)
    self.ChatOverview:SetWidth(self:GetWidth() * RIGHT_SIDE_WIDTH_SCALE)
    self.VoiceChatRoom:SetWidth(self:GetWidth() * RIGHT_SIDE_WIDTH_SCALE)
    
    self:SetExpansionPalette(10)
    --self:ClearPalette()

	EventRegistry:RegisterCallback("MythicWhispers.DeleteConversation", self.DeleteConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.AddLog", self.AddLog, self);
	EventRegistry:RegisterCallback("MythicWhispers.CreateConversation", self.CreateConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.OpenConversation", self.CreateConversation, self);
	EventRegistry:RegisterCallback("MythicWhispers.HandleJoinRequest", self.HandleJoinRequest, self);
	EventRegistry:RegisterCallback("MythicWhispers.OpenVoiceChatRoom", self.RequestMuteStatusUpdate, self);
	EventRegistry:RegisterCallback("MythicWhispers.SendMessageRead", self.SendMessageRead, self);

    C_ChatInfo.RegisterAddonMessagePrefix(addonName)

    self:SetScript("OnEvent", function(selfFrame, event, ...)
        if(event == "CHAT_MSG_WHISPER") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...

            EventRegistry:TriggerEvent("MythicWhispers.CreateConversation", playerName, guid)
            EventRegistry:TriggerEvent("MythicWhispers.AddLog", playerName, text, "character")
            EventRegistry:TriggerEvent("MythicWhispers.RefreshConversation", playerName)

        elseif(event == "CHAT_MSG_WHISPER_INFORM") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...

            EventRegistry:TriggerEvent("MythicWhispers.CreateConversation", playerName, guid)
            EventRegistry:TriggerEvent("MythicWhispers.AddLog", playerName, text, "player")
            EventRegistry:TriggerEvent("MythicWhispers.RefreshConversation", playerName)

        elseif(event == "PLAYER_ENTERING_WORLD") then
            if(not C_VoiceChat.IsLoggedIn()) then
                C_VoiceChat.Login()

            else
                self:RefreshVoiceChatServiceStatus()
                
                local channelID = C_VoiceChat.GetActiveChannelID()

                if(channelID) then
                    self:SetVoiceChatCallStatusColor(channelID)
                    
                end
            end

            self.ChatList:RefreshConversationButtons()
            self:RequestMuteStatusUpdate()

            MythicWhispers:TriggerChatTypeEvent()

        elseif(event == "VOICE_CHAT_CHANNEL_ACTIVATED") then
            self:SetVoiceChatCallStatusColor(...)

        elseif(event == "VOICE_CHAT_CHANNEL_MEMBER_ADDED" or event == "VOICE_CHAT_CHANNEL_MEMBER_REMOVED") then
            if(self.VoiceChatRoom:IsShown()) then
                self.VoiceChatRoom:Refresh()

            end
        elseif(event == "VOICE_CHAT_CHANNEL_JOINED") then
            local status, channelID, channelType, clubId, streamId = ...

            local channel = C_VoiceChat.GetChannelForChannelType(channelType)

            if(channel) then
                C_VoiceChat.ActivateChannel(channel.channelID)

            end
        elseif(event == "VOICE_CHAT_CHANNEL_REMOVED") then
            self:SetVoiceChatCallStatusColor()

        elseif(event == "VOICE_CHAT_LOGIN") then
            self:RefreshVoiceChatServiceStatus()

            if(requestPending) then
                self:HandleJoinRequest(requestPending.id1, requestPending.id2)

            end
        
        elseif(event == "VOICE_CHAT_LOGOUT") then
            self:RefreshVoiceChatServiceStatus()

            requestPending = {}

        elseif(event == "VOICE_CHAT_PENDING_CHANNEL_JOIN_STATE") then
            local channelType, clubId, streamId, pendingJoin = ...

        elseif(event == "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED") then
            self:SendMuteStatusUpdate()

        elseif(event == "CHAT_MSG_ADDON_LOGGED") then
            local prefix, cborText, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

            local tbl = MythicWhispers.ReadCBOR(cborText)
            tbl.sender = sender

            if(tbl.event == "VOICE_CHAT_CHANNEL_TRANSMIT_REQUEST") then
                self:SendMuteStatusUpdate()

            elseif(tbl.event == "TEXT_MESSAGE_READ") then
                self:SetMessageRead(tbl)
                EventRegistry:TriggerEvent("MythicWhispers.RefreshConversation", sender)

                
            end
        end
    end)

    

    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_ACTIVATED")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_JOINED")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_REMOVED")
    self:RegisterEvent("VOICE_CHAT_PENDING_CHANNEL_JOIN_STATE")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_MEMBER_GUID_UPDATED")

    self:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED")

    self:RegisterEvent("VOICE_CHAT_CHANNEL_MEMBER_ADDED")
    self:RegisterEvent("VOICE_CHAT_CHANNEL_MEMBER_REMOVED")
    self:RegisterEvent("VOICE_CHAT_LOGIN")
    self:RegisterEvent("VOICE_CHAT_LOGOUT")
end