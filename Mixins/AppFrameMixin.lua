local addonName, mw = ...

AppFrameMixin = {}

mw.C = {
    STANDARD_FILE_PATH = "Interface/Addons/" .. addonName .. "/res"
}

local MULTIPLICATOR = 0.8

local BACKDROP_INFO = {
    edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1
}

local EXPANSIONS = {
	[0] = {name = "Classic", background = "vanilla-bg-1", logo = GetExpansionDisplayInfo(0).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/0.png"},
	[1] = {name = "The Burning Crusade", background = "tbc-bg-1", logo = GetExpansionDisplayInfo(1).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/1.png"},
	[2] = {name = "Wrath of the Lich King", background = "wotlk-bg-1", logo = GetExpansionDisplayInfo(2).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/2.png"},
	[3] = {name = "Cataclysm", background = "cata-bg-1", logo = GetExpansionDisplayInfo(3).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/3.png"},
	[4] = {name = "Mists of Pandaria", background = "mop-bg-1", logo = GetExpansionDisplayInfo(4).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/4.png"},
	[5] = {name = "Warlords of Draenor", background = "wod-bg-1", logo = GetExpansionDisplayInfo(5).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/5.png"},
	[6] = {name = "Legion", background = "legion-bg-1", logo = GetExpansionDisplayInfo(6).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/6.png"},
	[7] = {name = "Battle for Azeroth", background = "bfa-bg-1", logo = GetExpansionDisplayInfo(7).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/7.png"},
	[8] = {name = "Shadowlands", background = "sl-bg-1", logo = GetExpansionDisplayInfo(8).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/8.png"},
	[9] = {name = "Dragonflight", background = "df-bg-1", logo = GetExpansionDisplayInfo(9).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/9.png"},
	[10] = {name = "The War Within", background = "tww-bg-1", logo = GetExpansionDisplayInfo(10).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/10.png", borderColor = CreateColor(0.35, 0.22, 0.1, 1)},
	[11] = {name = "Midnight", background = "mn-bg-1", logo = GetExpansionDisplayInfo(11).logo, icon = mw.C.STANDARD_FILE_PATH .. "/expansionIcons/11.png", borderColor = CreateColor(0, 0.12, 0.25, 1)},
}


function AppFrameMixin:CreatePlayerLogs(playerName)
    MW_ChatLogs[playerName] = {
        picture = nil,
        name = playerName,
        numOfUnreadMessages = 0,
        messages = {}
    }
end

function AppFrameMixin:SetColorPalette(expansion)
    local expansionData = EXPANSIONS[expansion]

    if(expansionData) then
        local background = EXPANSIONS[expansion].background
        local filePath = mw.C.STANDARD_FILE_PATH .. "/backgrounds/" .. background .. ".png"

        self.TitleBar:SetBackdrop(BACKDROP_INFO)
        self.TitleBar:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.TitleBar.Background:SetTexture(filePath)
        self.TitleBar.Background:SetTexCoord(0, 1, 0, 0.05)

        self.ChatList:SetBackdrop(BACKDROP_INFO)
        self.ChatList:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.ChatList.Background:SetTexture(filePath)
        self.ChatList.Background:SetTexCoord(0, 0.2, 0.055, 1)

        self.ChatOverview:SetBackdrop(BACKDROP_INFO)
        self.ChatOverview:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())
        self.ChatOverview.Background:SetTexture(filePath)
        self.ChatOverview.Background:SetTexCoord(0.2, 1, 0.055, 1)

        self.ChatOverview.Header:SetBackdrop(BACKDROP_INFO)
        self.ChatOverview.Header:SetBackdropColor(0, 0, 0, 0)
        self.ChatOverview.Header:SetBackdropBorderColor(expansionData.borderColor:GetRGBA())

    end
end

function AppFrameMixin:OnLoad()
    self:SetSize(GetScreenWidth() * MULTIPLICATOR, GetScreenHeight() * MULTIPLICATOR)
    self.ChatList:SetWidthViaParentWidth(self:GetWidth())
    self.ChatOverview:SetWidthViaParentWidth(self:GetWidth())
    
    self:SetColorPalette(10)

    self:SetScript("OnEvent", function(selfFrame, event, ...)
        if(event == "CHAT_MSG_WHISPER") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...

            if(playerName) then
                local logs = MW_ChatLogs[playerName]

                if(not logs) then
                    self:CreatePlayerLogs(playerName)

                    logs = MW_ChatLogs[playerName]
                end

                logs.unitGUID = guid
                logs.numOfUnreadMessages = logs.numOfUnreadMessages + 1

                tinsert(logs.messages, {
                    sender="character",
                    message = text,
                    date = C_DateAndTime.GetCurrentCalendarTime(),
                    viewed = false,
                    timestamp = GetServerTime(),
                })
            end

            self:Refresh()

        elseif(event == "CHAT_MSG_WHISPER_INFORM") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...

            if(playerName) then
                local logs = MW_ChatLogs[playerName]

                if(not logs) then
                    self:CreatePlayerLogs(playerName)

                    logs = MW_ChatLogs[playerName]

                end

                logs.unitGUID = guid

                tinsert(logs.messages, {
                    sender="player",
                    message = text,
                    date = C_DateAndTime.GetCurrentCalendarTime(),
                    viewed = true,
                    timestamp = GetServerTime(),
                })
            end

            self:Refresh()

        elseif(event == "CHAT_MSG_SYSTEM") then
            local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...
            if(text == format(ERR_CHAT_PLAYER_NOT_FOUND_S, playerName2)) then
                print("YEEEEEE")

            elseif(text == format(WHO_NUM_RESULTS, 1)) then
                self.ChatOverview.Header.Time:SetText(FRIENDS_LIST_ONLINE)
                self.ChatOverview.Header.Time:SetTextColor(GREEN_FONT_COLOR:GetRGBA())

            else
                print(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons)

            end

        elseif(event == "PLAYER_ENTERING_WORLD") then
            self:Refresh()

        end
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function AppFrameMixin:Refresh()
    self.ChatList:Refresh()
    self.ChatOverview:Refresh()

end