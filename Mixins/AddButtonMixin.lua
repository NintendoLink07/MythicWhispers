AddButtonMixin = {}

function AddButtonMixin:OnLoad()

end

function AddButtonMixin:OnClick()
    local playerName = self:GetParent().NameBox:GetText()

    if(playerName ~= "") then
        local nameBox = self:GetParent().NameBox
        nameBox:SetText("")
        nameBox:ClearFocus()

        EventRegistry:TriggerEvent("MythicWhispers.CreateConversation", playerName)
        EventRegistry:TriggerEvent("MythicWhispers.OpenConversation", playerName)
    end
end