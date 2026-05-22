local addonName, mw = ...

local function isUnitID(str)
    str = string.lower(str)

    if(string.find(str, "raid") or string.find(str, "party") or string.find(str, "player") or string.find(str, "target")) then
        return true

    end

    return false
end

function mw.CreateFullNameValuesFrom(type, value)
	if(not value) then
		return
		
	end

	if(not type) then
		type = isUnitID(value) and "unitID" or "unitName"

	end

	local fullName, shortName, realm

	local localRealm = GetNormalizedRealmName() or ""

	if(type == "unitName") then
		if(string.find(value, "-")) then
			fullName = value

			local nameTable = strsplittable("-", fullName)
			shortName = nameTable[1]
			realm = nameTable[2]

		else
			shortName = value
			realm = localRealm
			fullName = value .. "-" .. localRealm

		end

	else
		if(value ~= "player") then
			local nameNoMod, realmNoMod = UnitNameUnmodified(value)

			if(nameNoMod) then

				shortName = nameNoMod

				if(realmNoMod) then
					realm = realmNoMod
					fullName = nameNoMod .. "-" .. realmNoMod

				else
					realm = localRealm
					fullName = nameNoMod .. "-" .. localRealm

				end
			end
		else
			shortName = UnitName("player")
			realm = localRealm
			fullName = shortName .. "-" .. localRealm

		end
	end

	return fullName, shortName, realm
end