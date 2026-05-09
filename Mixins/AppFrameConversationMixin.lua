AppFrameConversationButtonMixin = {}

function AppFrameConversationButtonMixin:OnLoad()

end

function AppFrameConversationButtonMixin:ShowNewMessages(numOfMessages)
    self.NewMessages:Show()
    self.NumberOfNewMessages:Show()

    if(numOfMessages) then
        self.NumberOfNewMessages:SetText(numOfMessages)

    end
end

function AppFrameConversationButtonMixin:HideNewMessages()
    self.NewMessages:Hide()
    self.NumberOfNewMessages:Hide()

end

function AppFrameConversationButtonMixin:SetData(data)
    if(data.unitGUID) then
        local localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName = GetPlayerInfoByGUID(data.unitGUID)

        if(englishClass) then
            self.Picture:SetColorTexture(C_ClassColor.GetClassColor(englishClass):GetRGBA())

        end
    end

    self.Name:SetText(data.name)
    self.LastMessage:SetText(data.message)
    self.Time:SetText(format("%02d:%02d", data.date.hour, data.date.minute))

    if(data.numOfUnreadMessages > 0) then
        self:ShowNewMessages(data.numOfUnreadMessages)

    else
        self:HideNewMessages()

    end

    self.name = data.name
end

function AppFrameConversationButtonMixin:OnClick()
    EventRegistry:TriggerEvent("MythicWhispers.OpenConversation", self.name)
    self:HideNewMessages()
end



AppFrameConversationMessageMixin = {}

function AppFrameConversationMessageMixin:Refresh()
    local data = self:GetData()
    self.sender = data.sender

    self.Message:SetText(data.message)
    self.Time:SetText(format("%02d:%02d", data.date.hour, data.date.minute))

    if(data.sender == "player") then
        self.Background:SetColorTexture(0.65, 1, 0.65, 1)

    else
        self.Background:SetColorTexture(1, 1, 1, 1)

    end
end