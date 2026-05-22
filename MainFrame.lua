local addonName, mw = ...
local wticc = WrapTextInColorCode

MW_ChatLogs = {}

local appFrame = CreateFrame("Frame", "MythicWhispers_AppFrame", UIParent, "MW_AppFrame")


SLASH_MYTHICWHISPERS1 = '/mw'

local function handler(msg, editBox)
	local command, rest = msg:match("^(%S*)%s*(.-)$")

	if(command == "options") then

    else
        appFrame:Show()

    end
end
SlashCmdList["MYTHICWHISPERS"] = handler