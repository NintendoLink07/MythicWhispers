local addonName, mw = ...

AppFrameVoiceChatRoomMixin = {}

local CHAT_FRAME_WIDTH_SCALE = 0.3

local muteStatusTable = {}
local playerColorTable = {}


function AppFrameVoiceChatRoomMixin:GetPlayerRGBA(playerName)
    local tbl = playerColorTable[playerName]

    if(tbl) then
        return tbl.r, tbl.g, tbl.b, 1
        
    else
        

    end
end


function AppFrameVoiceChatRoomMixin:FindPlayerFrame(playerName)
    for frame in self.framePool:EnumerateActive() do
        if(frame.fullName == playerName) then
            return frame

        end
    end
end

function AppFrameVoiceChatRoomMixin:RefreshChatType(type)
    local voiceTextChat = self.ChatContainer.Chat

    voiceTextChat:UnregisterAllMessageGroups()

    if(type) then
        if(type == "NULL") then
            print("JA WAS IS'N DES; IS JA A NULL")

        elseif(type == "CUSTOM") then
            print("EI DES IS A CUSTOM; HEIßT BESONDERS")

        elseif(type == "RAID") then
            voiceTextChat:AddMessageGroup("RAID")
            voiceTextChat:AddMessageGroup("RAID_LEADER")
            voiceTextChat:AddMessageGroup("RAID_WARNING")

        elseif(type == "PARTY") then
            voiceTextChat:AddMessageGroup("PARTY")
            voiceTextChat:AddMessageGroup("PARTY_LEADER")

        elseif(type == "INSTANCE") then
            voiceTextChat:AddMessageGroup("INSTANCE_CHAT")
            voiceTextChat:AddMessageGroup("INSTANCE_CHAT_LEADER")

        elseif(type == "GUILD") then
            voiceTextChat:AddMessageGroup("GUILD")
            voiceTextChat:AddMessageGroup("OFFICER")

        elseif(type == "COMMUNITY") then
            print("JA DES IS A COMMUNITY")

        end
    end
end

function AppFrameVoiceChatRoomMixin:OnEvent(event, ...)
    if(event == "GROUP_ROSTER_UPDATE") then
        self:Refresh()

    elseif(event == "VOICE_CHAT_CHANNEL_ACTIVATED") then
        MythicWhispers:RefreshChatType()

    elseif(event == "CHAT_MSG_ADDON_LOGGED") then
        local prefix, cborText, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

        local text = MythicWhispers.ReadCBOR(cborText)

        if(string.find(text, "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED_")) then
            if(text == "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED_TRUE") then
                muteStatusTable[sender] = true
                
            elseif(text == "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED_FALSE") then
                muteStatusTable[sender] = false
                
            end

            local frame = self:FindPlayerFrame(sender)

            if(frame) then
                frame:SetSelfMuted(muteStatusTable[sender])

            end
        end
    end
end

function AppFrameVoiceChatRoomMixin:OnLoad()
	EventRegistry:RegisterCallback("MythicWhispers.OpenConversation", function() self:Hide() end, self);
	EventRegistry:RegisterCallback("MythicWhispers.OpenVoiceChatRoom", self.Refresh, self);
	EventRegistry:RegisterCallback("MythicWhispers.ChatTypeChanged", self.RefreshChatType, self);

    self:RegisterEvent("VOICE_CHAT_CHANNEL_ACTIVATED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_ADDON_LOGGED")

    self.GridManageFrame.Grid.childXPadding = 4
    self.GridManageFrame.Grid.childYPadding = 4

    self.framePool = CreateFramePool("Button", self.GridManageFrame.Grid, "MW_AppFrameVoiceChatRoomMemberTemplate", function(_, frame)
        frame:Hide()
        frame.gridRow = nil
        frame.gridColumn = nil
        
        frame.fullName = nil
        frame.memberID = nil
        frame.channelID = nil
        frame.selfMuted = nil

    end)

    self.ChatContainer.Chat.messageTypeList = {}
    self.ChatContainer.Chat:SetFontObject(ChatFontNormal)
    self.ChatContainer.Chat:SetJustifyH("LEFT")
    self.ChatContainer.Chat:SetMaxLines(128)
    self.ChatContainer.Chat:SetFading(false)

    self.ChatContainer.Chat:SetScript("OnEvent", function(selfFrame, event, ...)
        selfFrame:MessageEventHandler(event, ...)
    end)

    -- Script to handle pressing "Enter"
    self.ChatContainer.EditBoxContainer.ChatEditBox:SetScript("OnEnterPressed", function(selfFrame)
        local text = selfFrame:GetText()
        if text and text ~= "" then
            -- Add the typed text directly to your message area
            C_ChatInfo.SendChatMessage(text, MythicWhispers:GetChatType())
            selfFrame:SetText("") -- Clear the box
        end
        selfFrame:ClearFocus() -- Close the input keyboard focus
    end)

    -- Script to handle pressing "Escape"
    self.ChatContainer.EditBoxContainer.ChatEditBox:SetScript("OnEscapePressed", function(selfFrame)
        selfFrame:ClearFocus()
    end)
end

function AppFrameVoiceChatRoomMixin:Refresh()
    local width = self:GetWidth()
    self.ChatContainer:SetWidth(width * CHAT_FRAME_WIDTH_SCALE)

    MythicWhispers:TriggerChatTypeEvent()

    self.framePool:ReleaseAll()

    self.GridManageFrame.Grid:ClearAllPoints()
    self.GridManageFrame.Grid:SetAllPoints()
    
    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        if(channel and channel.isActive) then
            local numMembers = #channel.members

            local frameWidth
            local frameHeight

            local scalar = 4 * ((40 - numMembers) / 100 + 1)

            local map = {
                [1] = {},
                [2] = {},
                [3] = {},
                [4] = {},
                [5] = {}
            }

            local row = 1

            for k, v in ipairs(channel.members) do
                local name = C_VoiceChat.GetMemberName(v.memberID, channelID)
                local guid = C_VoiceChat.GetMemberGUID(v.memberID, channelID)

                local fullName = MythicWhispers.CreateFullNameValuesFrom("unitName", name)

                local frame = self.framePool:Acquire()
                frame.fullName = fullName

                if(not frame.origW) then
                    frame.origW = frame:GetWidth()
                    frame.origH = frame:GetHeight()

                end

                frame:SetWidth(frame.origW * scalar)
                frame:SetHeight(frame.origH * scalar)

                if(not frameWidth) then
                    frameWidth = frame:GetWidth()
                    frameHeight = frame:GetHeight()

                end

                tinsert(map[row], frame)

                frame.gridRow = row
                frame.gridColumn = #map[row]

                frame.memberID = v.memberID
                frame.channelID = channelID

                if(not playerColorTable[frame.fullName]) then
                    playerColorTable[frame.fullName] = {
                        r = random(35, 75) / 100,
                        g = random(35, 75) / 100,
                        b = random(35, 75) / 100,
                    }

                end

                frame.Background:SetColorTexture(self:GetPlayerRGBA(frame.fullName))

                frame:SetSelfMuted(muteStatusTable[frame.fullName])

                frame.Name:SetText(name)

                frame:Show()

                local numOfElementsInRow = #map[row]

                row = numOfElementsInRow == 8 and row + 1 or row

            end

            local gridWidth = numMembers > 7 and frameWidth * 8 or frameWidth * numMembers
            local gridHeight = ceil(numMembers / 8) * frameHeight
            
            self.GridManageFrame.Grid:ClearAllPoints()
            self.GridManageFrame.Grid:SetSize(gridWidth, gridHeight)
            self.GridManageFrame.Grid:MarkDirty()
            self.GridManageFrame.Grid:SetPoint("CENTER")
        end
    end

    self:Show()
end