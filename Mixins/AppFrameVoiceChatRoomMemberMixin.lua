AppFrameVoiceChatRoomMemberMixin = {}

function AppFrameVoiceChatRoomMemberMixin:OnLoad()
    self:RegisterEvent("VOICE_CHAT_CHANNEL_MEMBER_MUTE_FOR_ME_CHANGED")

end

function AppFrameVoiceChatRoomMemberMixin:OnEvent(event, ...)
    if(event == "VOICE_CHAT_CHANNEL_MEMBER_MUTE_FOR_ME_CHANGED") then
        self:Refresh()
    end
end

function AppFrameVoiceChatRoomMemberMixin:OnClick(...)
    if(... == "RightButton") then
        local currentMenu = MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
            local isPlayer = C_VoiceChat.IsMemberLocalPlayer(self.memberID, self.channelID)
            local name = self.Name:GetText()

			rootDescription:CreateTitle(isPlayer and format(CHALLENGE_MODE_GUILD_BEST_LINE_YOU, "FFffd100", name, "") or name);
			rootDescription:SetTag("MW_VOICECHATROOM_MEMBER")

            local location = PlayerLocation:CreateFromVoiceID(self.memberID, self.channelID)

			rootDescription:CreateButton(isPlayer and (C_VoiceChat.IsMuted() and VOICE_TOOLTIP_UNMUTE_MIC or VOICE_TOOLTIP_MUTE_MIC) or (C_VoiceChat.IsMemberMuted(location) and VOICE_TOOLTIP_UNMUTE_MIC or VOICE_TOOLTIP_MUTE_MIC), function()
                if(isPlayer) then
                    C_VoiceChat.SetMuted(not C_VoiceChat.IsMuted())

                else
                    C_VoiceChat.SetMemberMuted(location, not C_VoiceChat.IsMemberMuted(location))

                end
            end)
        end)
    end
end

function AppFrameVoiceChatRoomMemberMixin:OnShow()
    self:Refresh()

end

function AppFrameVoiceChatRoomMemberMixin:IsNotStale()
    return C_VoiceChat.GetMemberGUID(self.memberID, self.channelID) ~= nil

end

function AppFrameVoiceChatRoomMemberMixin:SetSelfMuted(bool)
    self.isSelfMuted = bool

    self:Refresh()
end

function AppFrameVoiceChatRoomMemberMixin:Refresh()
    if(self.memberID and self.channelID) then
        if(self:IsNotStale()) then
            local location = PlayerLocation:CreateFromVoiceID(self.memberID, self.channelID)

            local silenced = C_VoiceChat.IsMemberSilenced(self.memberID, self.channelID)
            local mutedForAll = C_VoiceChat.IsMemberMutedForAll(self.memberID, self.channelID)
            local mutedForMe
            
            if(location) then
                mutedForMe = C_VoiceChat.IsMemberMuted(location)
                
            end

            if(self.isSelfMuted) then
                self.MicStatus:SetAtlas("voicechat-icon-mic-mutesilenced")
                
            elseif(mutedForMe) then
                self.MicStatus:SetAtlas("chatframe-button-icon-mic-off")
                
            else
                self.MicStatus:SetTexture(nil)

            end
        end
    end
end