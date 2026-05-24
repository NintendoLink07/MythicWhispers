local addonName, mw = ...

mw.network = {
    playerConnections = {}

}

function mw.network:GetLineID(playerName)
    return self.playerConnections[playerName] and self.playerConnections[playerName].lineID

end

function mw.network:HasConnectionEstablished(playerName)
    return self.playerConnections[playerName] and self.playerConnections[playerName].connectionEstablished

end

function mw.network:SetConnectionEstablished(playerName, bool)
    self.playerConnections[playerName].connectionEstablished = bool

end

function mw.network:SaveFunctionToBeExecuted(playerName, func)
    self.playerConnections[playerName].func = func

end

function mw.network:GetFunctionToBeExecuted(playerName)
    return self.playerConnections[playerName].func

end

function mw.network:SaveOriginalTable(playerName, tbl)
    self.playerConnections[playerName].originalTable = tbl

end

function mw.network:GetOriginalTable(playerName)
    return self.playerConnections[playerName].originalTable

end

function mw.network:CreatePlayerLineTableIfNeeded(playerName)
    if(not self.playerConnections[playerName]) then
        self.playerConnections[playerName] = {
            connectionEstablished = false,
            func = nil,
            originalTable = nil,
            lineID = 0
        }

    end

end

function mw.network:IncreaseSynchronizedLineID(playerName)
    self.playerConnections[playerName].lineID = self.playerConnections[playerName].lineID + 1

end

function mw.network:SendSynchronize(playerName)
    local tbl = {
        event = "CONNECTION_SYN",
        currentLineID = self:GetLineID(playerName)
    }

    C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), "WHISPER", playerName)

end

function mw.network:SendAcknowledge(playerName)
    local tbl = {
        event = "CONNECTION_ACK",
        currentLineID = self:GetLineID(playerName)
    }

    C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), "WHISPER", playerName)

end

function mw.network:SendSynchronizeAndAcknowledge(playerName)
    local tbl = {
        event = "CONNECTION_SYN_ACK",
        currentLineID = self:GetLineID(playerName)
    }

    C_ChatInfo.SendAddonMessageLogged("MYTHICWHISPERS", MythicWhispers.WriteCBOR(tbl), "WHISPER", playerName)

end

function mw.network:CompareLineIDs(playerName, lineID)
    local savedLineID = self:GetLineID(playerName)

    if(savedLineID == lineID) then
        return true

    else
        return false

    end

end

function mw.network:ManageNetworkEvents(tbl)
    local event = tbl.event
    local playerName = tbl.sender
    local currentLineID = tbl.currentLineID

    self:CreatePlayerLineTableIfNeeded(playerName)

    if(event == "CONNECTION_SYN") then
        self:SendSynchronizeAndAcknowledge(playerName)

    elseif(event == "CONNECTION_SYN_ACK") then
        self:SendAcknowledge(playerName)
        self:SetConnectionEstablished(playerName, true)

    elseif(event == "CONNECTION_ACK") then
        self:SetConnectionEstablished(playerName, true)

    elseif(not self:HasConnectionEstablished(playerName)) then
        self:SaveOriginalTable(playerName, tbl)
        self:SendSynchronize(playerName)

    end

    if(self:HasConnectionEstablished(playerName)) then
        print(event, playerName, currentLineID, self:GetLineID(playerName))
        self:IncreaseSynchronizedLineID(playerName)
        
        local originalTable = self:GetOriginalTable(playerName)
        EventRegistry:TriggerEvent("MythicWhispers.HandleCustomAddonEvents", originalTable)
    end


    --if(self:CompareLineIDs(tbl.sender, tbl.currentLineID)) then
        
    --end
end