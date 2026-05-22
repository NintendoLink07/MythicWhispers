AppFrameConversationDaystampMixin = {}

function AppFrameConversationDaystampMixin:OnLoad()

end

function AppFrameConversationDaystampMixin:Refresh()
    local data = self:GetData()

    local weekDay = CALENDAR_WEEKDAY_NAMES[data.date.weekday]
    local month = CALENDAR_FULLDATE_MONTH_NAMES[data.date.month]
    self.Date:SetText(format("%s, %d %s %d", weekDay, data.date.monthDay, month, data.date.year))

end