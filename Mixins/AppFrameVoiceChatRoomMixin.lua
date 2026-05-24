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
        MythicWhispers:TriggerChatTypeEvent()

    elseif(event == "CHAT_MSG_ADDON_LOGGED") then
        local prefix, cborText, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

        local tbl = MythicWhispers.ReadCBOR(cborText)

        if(tbl == "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED") then
            muteStatusTable[sender] = tbl.muted

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
            local numMembers = #channel.members * 10

            -- 1. Calculate ideal grid dimensions
            -- math.ceil and math.sqrt work identically to modern languages
            local cols = ceil(sqrt(numMembers))
            local rows = ceil(numMembers / cols)

            for k, v in ipairs(channel.members) do
                local zeroIdx = k - 1
                local r = math.floor(zeroIdx / cols)
                local c = zeroIdx % cols

                -- Standard 1-based positioning for your UI engine
                local gridRow = r + 1
                local gridColumn = c + 1

                -- Base sizes
                local rowSize = 1
                local colSize = 1

                -- --- DYNAMIC SPANNING LOGIC ---

                -- Check how many members are actually in this specific row
                local totalMembersInThisRow = cols
                local isLastRow = (r == rows - 1)
                
                if isLastRow then
                    totalMembersInThisRow = numMembers - (r * cols)
                end

                -- Calculate how many grid columns each member in this row should span.
                -- We divide total columns by how many members need to share this row.
                colSize = math.floor(cols / totalMembersInThisRow)

                -- Adjust the column positioning so they line up side-by-side perfectly
                gridColumn = (c * colSize) + 1

                -- If it's the absolute last member of an uneven row, stretch it to 
                -- absorb any remaining fractional columns left over from rounding.
                if k == numMembers then
                    local currentRightEdge = gridColumn + colSize - 1
                    if currentRightEdge < cols then
                        colSize = colSize + (cols - currentRightEdge)
                    end
                end

                -- If the entire grid has empty space vertically (e.g., 2 members in a 2x2 grid context, 
                -- or a layout that doesn't use all rows), stretch the rowSize to fill the height.
                if rows > numMembers then
                    rowSize = math.floor(rows / numMembers)
                    gridRow = (r * rowSize) + 1
                end

                local frame = self.framePool:Acquire()

                frame.gridRow = gridRow
                frame.gridColumn = gridColumn
                frame.gridRowSize = rowSize
                frame.gridColumnSize = colSize

                print(frame.gridRow, frame.gridColumn, frame.gridRowSize, frame.gridColumnSize)

                local name = C_VoiceChat.GetMemberName(v.memberID, channelID)

                if(name) then
                    local guid = C_VoiceChat.GetMemberGUID(v.memberID, channelID)
                    local fullName = MythicWhispers.CreateFullNameValuesFrom("unitName", name)

                    frame.fullName = fullName
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

                else
                    frame.Name:SetText(UNKNOWN)
                    frame.Background:SetColorTexture(1, 1, 1, 1)
                    frame:SetSelfMuted(false)

                end

                frame:Show()
            end
            
            self.GridManageFrame.Grid:MarkDirty()
            self.GridManageFrame.Grid:SetAllPoints()
        end
    end

    self:Show()
end