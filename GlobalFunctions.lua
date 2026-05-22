local addonName, mw = ...

_G.MythicWhispers = mw

function MythicWhispers:TriggerChatTypeEvent()
    local channelID = C_VoiceChat.GetActiveChannelID()

    if(channelID) then
        local channel = C_VoiceChat.GetChannel(channelID)

        if(channel) then
            local channelType = channel.channelType

            if(channelType) then
                if(channelType == 0) then
                    mw.chatType = "NULL"

                elseif(channelType == 1) then
                    mw.chatType = "CUSTOM"

                elseif(channelType == 2) then
                    mw.chatType = IsInRaid() and "RAID" or "PARTY"

                elseif(channelType == 3) then
                    mw.chatType = "INSTANCE"

                elseif(channelType == 4) then
                    if(channel.clubId == C_Club.GetGuildClubId()) then
                        mw.chatType = "GUILD" -- /OFFICER

                    elseif(channel.clubId and channel.streamId) then
                        mw.chatType = "COMMUNITY"

                    end
                end
            end
        end
    end

    EventRegistry:TriggerEvent("MythicWhispers.ChatTypeChanged", mw.chatType)

end

function MythicWhispers:GetChatType()
    return mw.chatType
    
end

function MythicWhispers.ReadCBOR(dataPayload)
    local decoded = C_EncodingUtil.DecodeBase64(dataPayload);
    assertsafe(decoded ~= nil, "Unable to decode serialized data");

    local inflated = C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate);
    return C_EncodingUtil.DeserializeCBOR(inflated);

end

function MythicWhispers.WriteCBOR(data)
    local serialized = C_EncodingUtil.SerializeCBOR(data);
    assertsafe(serialized ~= nil, "Unable to serialize data");

    local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate);
    local encoded = C_EncodingUtil.EncodeBase64(compressed);
    assertsafe(encoded ~= nil, "Unable to encode cooldowns");

    return encoded;
end