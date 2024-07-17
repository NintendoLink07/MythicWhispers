local addonName, ns = ...
local wticc = WrapTextInColorCode

ns.WEIGHTS_TABLE = {
	[1] = 10000,
	[2] = 100,
	[3] = 1,
}

ns.ITEM_QUALITY_COLORS = _G["ITEM_QUALITY_COLORS"]

for _, colorElement in pairs(ns.ITEM_QUALITY_COLORS) do
	colorElement.pureHex = colorElement.color:GenerateHexColor()
	colorElement.desaturatedRGB = {colorElement.r * 0.65, colorElement.g * 0.65, colorElement.b * 0.65}
	colorElement.desaturatedHex = CreateColor(unpack(colorElement.desaturatedRGB)):GenerateHexColor()
end

ns.CLRSCC = { -- from clrs.cc
	["navy"] = "FF001F3F",
	["blue"] = "FF0074D9",
	["aqua"] = "FF7FDBFF",
	["teal"] = "FF39CCCC",
	["purple"] = "FFB10DC9",
	["fuchsia"] = "FFF012BE",
	["maroon"] = "FF85144b",
	["red"] = "FFFF4136",
	["orange"] = "FFFF851B",
	["yellow"] = "FFFFDC00",
	["olive"] = "FF3D9970",
	["green"] = "FF2ECC40",
	["lime"] = "FF01FF70",
	["black"] = "FF111111",
	["gray"] = "FFAAAAAA",
	["silver"] = "FFDDDDDD",
	["white"] = "FFFFFFFF",
}

ns.DIFFICULTY = {
	[4] = {shortName = "M+", description = "Mythic+", color = ns.ITEM_QUALITY_COLORS[5].pureHex, desaturated = ns.ITEM_QUALITY_COLORS[5].desaturatedHex, miogColors = ns.ITEM_QUALITY_COLORS[5].color},
	[3] = {shortName = "M", description = _G["PLAYER_DIFFICULTY6"], color = ns.ITEM_QUALITY_COLORS[4].pureHex, desaturated = ns.ITEM_QUALITY_COLORS[4].desaturatedHex, miogColors = ns.ITEM_QUALITY_COLORS[4].color},
	[2] = {shortName = "H", description = _G["PLAYER_DIFFICULTY2"], color = ns.ITEM_QUALITY_COLORS[3].pureHex, desaturated = ns.ITEM_QUALITY_COLORS[3].desaturatedHex, miogColors = ns.ITEM_QUALITY_COLORS[3].color},
	[1] = {shortName = "N", description = _G["PLAYER_DIFFICULTY1"], color = ns.ITEM_QUALITY_COLORS[2].pureHex, desaturated = ns.ITEM_QUALITY_COLORS[2].desaturatedHex, miogColors = ns.ITEM_QUALITY_COLORS[2].color},
	[0] = {shortName = "LT", description = "Last tier", color = ns.ITEM_QUALITY_COLORS[0].pureHex, desaturated = ns.ITEM_QUALITY_COLORS[0].desaturatedHex, miogColors = ns.ITEM_QUALITY_COLORS[0].color},
	[-1] = {shortName = "NT", description = "No tier", color = "FFFF2222", desaturated = "ffe93838"},
}

ns.COLOR_BREAKPOINTS = {
	[0] = {breakpoint = 0, hex = "ff9d9d9d", r = 0.62, g = 0.62, b = 0.62},
	[1] = {breakpoint = 700, hex = "ffffffff", r = 1, g = 1, b = 1},
	[2] = {breakpoint = 1400, hex = "ff1eff00", r = 0.12, g = 1, b = 0},
	[3] = {breakpoint = 2100, hex = "ff0070dd", r = 0, g = 0.44, b = 0.87},
	[4] = {breakpoint = 2800, hex = "ffa335ee", r = 0.64, g = 0.21, b = 0.93},
	[5] = {breakpoint = 3500, hex = "ffff8000", r = 1, g = 0.5, b = 0},
	[6] = {breakpoint = 4200, hex = "ffe6cc80", r = 0.9, g = 0.8, b = 0.5},
}

local function calculateWeightedScore(difficulty, kills, bossCount, current, ordinal)
	return (ns.WEIGHTS_TABLE[current and 1 or 2] * difficulty + ns.WEIGHTS_TABLE[current and 2 or 3] * kills / bossCount) + (ns.WEIGHTS_TABLE[current and 1 or 2] * difficulty + ns.WEIGHTS_TABLE[current and 2 or 3] * kills / bossCount)

end

local function getRaidSortData(playerName)
	local profile

	if(ns.F.IS_RAIDERIO_LOADED) then
		profile = RaiderIO.GetProfile(playerName)

	end

	--[[

		raidProgress table
			1 table
				current bool
				isMainProgress bool

				raid table
					bossCount number
					id number
					mapID number
					ordinal number
					name string
					shortName string

				progress table
					1
						cleared bool
						obsolete bool
						difficulty number
						kills number
						progress table
							1
								killed bool
								count number
								difficulty number
								index number

				



	]]

	local currentData = {}
	local nonCurrentData = {}
	local mainData = {}
	local orderedData = {}

	if(profile and profile.success == true) then
		if(profile.raidProfile) then

			for k, d in ipairs(profile.raidProfile.raidProgress) do
				if(d.isMainProgress == false) then
					if(d.current == true) then
						local highestDifficulty = 1

						for x, y in ipairs(d.progress) do
							local mapID
							local awakened = false

							if(string.find(d.raid.mapId, 10000)) then
								mapID = tonumber(strsub(d.raid.mapId, strlen(d.raid.mapId) - 3))
								awakened = d.current
							else
								mapID = d.raid.mapId

							end

							if(highestDifficulty < y.difficulty) then
								highestDifficulty = y.difficulty
							end

							currentData[#currentData+1] = {
								ordinal = d.raid.ordinal,
								raidProgressIndex = k,
								mapId = mapID,
								difficulty = y.difficulty,
								current = d.current,
								shortName = d.raid.shortName,
								progress = y.kills,
								bossCount = d.raid.bossCount,
								parsedString = y.kills .. "/" .. d.raid.bossCount,
								weight = calculateWeightedScore(y.difficulty, y.kills, d.raid.bossCount, d.current, d.raid.ordinal)
							}
							
						end
					elseif(d.current == false) then

						local highestDifficulty = 1

						for x, y in ipairs(d.progress) do
							local mapID
							local awakened = false

							if(string.find(d.raid.mapId, 10000)) then
								mapID = tonumber(strsub(d.raid.mapId, strlen(d.raid.mapId) - 3))
								awakened = true

							else
								mapID = d.raid.mapId

							end

							if(highestDifficulty < y.difficulty) then
								highestDifficulty = y.difficulty
							end

							nonCurrentData[#nonCurrentData+1] = {
								ordinal = d.raid.ordinal,
								raidProgressIndex = k,
								mapId = mapID,
								difficulty = y.difficulty,
								current = d.current,
								shortName = d.raid.shortName,
								progress = y.kills,
								bossCount = d.raid.bossCount,
								parsedString = y.kills .. "/" .. d.raid.bossCount,
								weight = calculateWeightedScore(y.difficulty, y.kills, d.raid.bossCount, d.current, d.raid.ordinal)
							}
						end
					end
				else
					for x, y in ipairs(d.progress) do
						local mapID
						local awakened = false

						if(string.find(d.raid.mapId, 10000)) then
							mapID = tonumber(strsub(d.raid.mapId, strlen(d.raid.mapId) - 3))
							awakened = true

						else
							mapID = d.raid.mapId

						end

						mainData[#mainData+1] = {
							ordinal = d.raid.ordinal,
							raidProgressIndex = k,
							mapId = mapID,
							difficulty = y.difficulty,
							current = d.current,
							shortName = d.raid.shortName,
							progress = y.kills,
							bossCount = d.raid.bossCount,
							parsedString = y.kills .. "/" .. d.raid.bossCount,
							weight = calculateWeightedScore(y.difficulty, y.kills, d.raid.bossCount, d.current, d.raid.ordinal)
						}
					end
				end
			end
		end
	end


	table.sort(currentData, function(k1, k2)
		return k1.difficulty > k2.difficulty
	end)

	table.sort(nonCurrentData, function(k1, k2)
		return k1.difficulty > k2.difficulty
	end)

	table.sort(mainData, function(k1, k2)
		return k1.difficulty > k2.difficulty
	end)

	if(currentData) then
		for k, v in ipairs(currentData) do
			orderedData[#orderedData+1] = v
		end
	end

	if(nonCurrentData) then
		for k, v in ipairs(nonCurrentData) do
			orderedData[#orderedData+1] = v
		end
	end

	if(#orderedData < 3) then
		for i = #orderedData + 1, 3, 1 do
			orderedData[i] = {
				difficulty = -1,
				progress = 0,
				bossCount = 0,
				parsedString = "0/0",
				weight = 0
			}
		end
	end


	for i = 1, 3, 1 do
		if(currentData[i] == nil) then
			currentData[i] = {
				difficulty = -1,
				progress = 0,
				bossCount = 0,
				parsedString = "0/0",
				weight = 0
			}
		end
	end

	for i = 1, 3, 1 do
		if(nonCurrentData[i] == nil) then
			nonCurrentData[i] = {
				difficulty = -1,
				progress = 0,
				bossCount = 0,
				parsedString = "0/0",
				weight = 0
			}
		end
	end
	
	for i = 1, 3, 1 do
		if(mainData[i] == nil) then
			mainData[i] = {
				difficulty = -1,
				progress = 0,
				bossCount = 0,
				parsedString = "0/0",
				weight = 0
			}
		end
	end

	return currentData, nonCurrentData, orderedData, mainData
end

ns.getRaidSortData = getRaidSortData

ns.createCustomColorForRating = function(score)
	if(score > 0) then
		for k, v in ipairs(ns.COLOR_BREAKPOINTS) do
			if(score < v.breakpoint) then
				local percentage = (v.breakpoint - score) / 700

				return CreateColor(v.r + (ns.COLOR_BREAKPOINTS[k - 1].r - v.r) * percentage, v.g + (ns.COLOR_BREAKPOINTS[k - 1].g - v.g) * percentage, v.b + (ns.COLOR_BREAKPOINTS[k - 1].b - v.b) * percentage)

			end
		end

		return CreateColor(0.9, 0.8, 0.5)
	else
		return CreateColorFromHexString(ns.CLRSCC.red)

	end
end