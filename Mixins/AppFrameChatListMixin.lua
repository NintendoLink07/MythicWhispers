AppFrameChatListMixin = {}

local dataProvider = CreateDataProvider()

local WIDTH_SCALE = 0.2

function AppFrameChatListMixin:OnLoad()
    local view = CreateScrollBoxListLinearView();

    function MW_CreateConversation(frame, data)
        frame:SetData(data)

    end

    view:SetElementFactory(function(factory, data)
        local template = data.template
        factory(template, MW_CreateConversation)

    end)
    view:SetPadding(3, 3, 3, 3, 4);

	local scrollBoxAnchorsWithBar = {
		CreateAnchor("TOPLEFT", 0, 0),
		CreateAnchor("BOTTOMRIGHT", -18, 0);
	}

	local scrollBoxAnchorsWithoutBar = {
		scrollBoxAnchorsWithBar[1],
		CreateAnchor("BOTTOMRIGHT", 0, 0);
	}

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    self.ScrollBox:SetDataProvider(dataProvider);
end

function AppFrameChatListMixin:SetWidthViaParentWidth(parentWidth)
    self:SetWidth(parentWidth * WIDTH_SCALE)
    
end

function AppFrameChatListMixin:SetDataCallback(data)
    return function()
        self:GetParent().ChatOverview:SetData(data)
    end

end

function AppFrameChatListMixin:Refresh()
    dataProvider:Flush()

    if(MW_ChatLogs) then
        local orderedList = {}

        for k, v in pairs(MW_ChatLogs) do
            local lastMessage = v.messages[#v.messages]
            tinsert(orderedList, {
                template = "MW_AppFrameConversationButton",
                unitGUID = v.unitGUID,
                name = v.name,
                picture = v.picture,
                sender = lastMessage.sender,
                message = lastMessage.message,
                date = lastMessage.date,
                timestamp = lastMessage.timestamp,
                numOfUnreadMessages = v.numOfUnreadMessages
            })

        end

        table.sort(orderedList, function(k1, k2)
            return k1.timestamp > k2.timestamp

        end)

        for k, v in ipairs(orderedList) do
            dataProvider:Insert(v)
        end
    end
end

function AppFrameChatListMixin:OnShow()
    self:Refresh()

end