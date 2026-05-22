local addonName, mw = ...
local wticc = WrapTextInColorCode

_G.MythicWhispers = mw

MW_ChatLogs = {}

local appFrame = CreateFrame("Frame", "MythicWhispers_AppFrame", UIParent, "MW_AppFrame")


function mw:SetChatType(type)
    mw.currentChatType = type
    
end

function mw:GetChatType(type)
    return mw.currentChatType
    
end

function mw:RefreshChatType()
    local channelID = C_VoiceChat.GetActiveChannelID()
    local voiceTextChat = self.VoiceChatRoom.ChatContainer.Chat

    voiceTextChat:UnregisterAllMessageGroups()

    print("ID", channelID)

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        if(channel) then
            local channelType = channel.channelType

            if(channelType) then
                if(channelType == 0) then
                    print("JA WAS IS'N DES; IS JA A NULL")

                elseif(channelType == 1) then
                    print("EI DES IS A CUSTOM; HEIßT BESONDERS")

                elseif(channelType == 2) then
                    if(IsInRaid()) then
                        voiceTextChat:AddMessageGroup("RAID")
                        voiceTextChat:AddMessageGroup("RAID_LEADER")
                        voiceTextChat:AddMessageGroup("RAID_WARNING")

                        self:SetChatType("RAID")

                    elseif(IsInGroup()) then
                        voiceTextChat:AddMessageGroup("PARTY")
                        voiceTextChat:AddMessageGroup("PARTY_LEADER")

                        self:SetChatType("PARTY")

                    end

                elseif(channelType == 3) then
                    voiceTextChat:AddMessageGroup("INSTANCE_CHAT")
                    voiceTextChat:AddMessageGroup("INSTANCE_CHAT_LEADER")

                    self:SetChatType("INSTANCE")

                elseif(channelType == 4) then
                    if(channel.clubId == C_Club.GetGuildClubId()) then
                        voiceTextChat:AddMessageGroup("GUILD")
                        voiceTextChat:AddMessageGroup("OFFICER")

                        self:SetChatType("GUILD")

                    elseif(channel.clubId and channel.streamId) then
                        print("JA DES IS A COMMUNITY")

                    end
                end
            end
        end
    end
end


SLASH_MYTHICWHISPERS1 = '/mw'

local function handler(msg, editBox)
	local command, rest = msg:match("^(%S*)%s*(.-)$")

	if(command == "options") then

    else
        appFrame:Show()

    end
end
SlashCmdList["MYTHICWHISPERS"] = handler