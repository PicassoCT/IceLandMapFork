function gadget:GetInfo()
	return {
		name = "feature placer",
		desc = "Spawns Features and Units",
		author = "Gnome, Smoth",
		date = "August 2008",
		license = "PD",
		layer = 452,
		enabled = true -- loaded by default?
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

if (Spring.GetGameFrame() >= 1) then
	return false
end

local SetUnitNeutral = Spring.SetUnitNeutral
local SetUnitBlocking = Spring.SetUnitBlocking
local SetUnitRotation = Spring.SetUnitRotation
local SetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local CreateUnit = Spring.CreateUnit
local CreateFeature = Spring.CreateFeature
local featurecfg = {}

VFS.Include("scripts/lib_jw.lua" )
VFS.Include("scripts/lib_OS.lua" )
VFS.Include("scripts/lib_UnitScript.lua" )
VFS.Include("scripts/lib_Build.lua" 	)



if VFS.FileExists("mapconfig/featureplacer/config.lua") then
	featurecfg = VFS.Include("mapconfig/featureplacer/config.lua")
	
	featureslist = featurecfg.objectlist
	buildinglist = featurecfg.buildinglist
	unitlist = featurecfg.unitlist
else
	Spring.Echo("Featureplacer: missing file")
	Spring.Echo("Featureplacer: No features loaded")
end

if ( featurecfg ) then
	local rotationMultiplier = math.pi / 32768
	local gaiaTeamID = Spring.GetGaiaTeamID()
	local featureSetFile = "mapconfig/featureplacer/config.lua"
	local losState = {los=true, prevLos=true, contRadar=true, radar=true}
	
	if ( featurecfg.featureslist ) then
		for i,fDef in pairs(featureslist) do
			local flagID = CreateFeature(fDef.name, fDef.x, Spring.GetGroundHeight(fDef.x,fDef.z)+5, fDef.z, fDef.rot)
		end
	end
	if ( featurecfg.buildinglist ) then
		
		pseudoRandomValues= {0.01,0.57,0.2,0.81,0.59,0.48,0.36,0.9,0.83,0.75,0.18,0.86,0.72,0.52,0.31,0.02,0.1,0.37,0.15,0.17,0.99,0.45,0.12,0.01,0.01,0.38,0.54,0.58,0.61,0.61,0.17,0.67,0.46,0.36,0.06,0.61,0.79,0.81,0.52,0.31,0.88,0.73,0.96,0.93,0.54,0.15,0.47,0.24,0.87,0.21,0.78,0.85,1,1,0.62,0.4,0.27,0.3,0.85,0.03,0.38,0.1,0.68,0.06,0.01,0.92,0.28,0.28,0.59,0.7,0.84,0.73,0.49,0.21,0.75,0.47,0.46,0.95,0.75,0.11,0.6,0.39,0.74,0.61,0.58,0.37,0.16,0.23,0.43,0.81,0.52,0.99,0.76,0.35,0.17,0.66,0.5,0.07,0.7,0.51}
		pseudoIndex=1
		
		function ceeiling(value)
			return value - (value % 1)
		end
		
		function absolut(value)
			if value < 0 then return value*-1 end
			return value
		end
		
		function randomStringifyHeading (deglow,degup)
			local result = 0
			if not degup then
				result = deglow 
			else
				pseudoIndex= (pseudoIndex %#pseudoRandomValues) +1
				positive= degup-deglow
				result = deglow + ceeiling(positive*pseudoRandomValues[pseudoIndex])
			end
			
			result = (((180 - absolut(result % 360))/180)*32767)..""
			return result
		end
	
		for _,uDef in pairs(featurecfg.buildinglist) do
			heigth= Spring.GetGroundHeight(uDef.x,uDef.z)
			local flagID = CreateUnit(uDef.name, uDef.x, heigth, uDef.z, 0, gaiaTeamID)
			local rotation = uDef.rot or "0"
			if not uDef.rot then rotation = randomStringifyHeading(uDef.rotLow, uDef.rotUp) end
			local unitRotation = -rotation * rotationMultiplier
			Spring.SetUnitRotation(flagID, 0, unitRotation, 0)
			Spring.SetUnitNeutral(flagID,true)
			Spring.SetUnitLosState(flagID,0, losState)
			SetUnitAlwaysVisible(flagID,true)

		end
		
		for _,uDef in pairs(featurecfg.unitlist) do
			heigth= Spring.GetGroundHeight(uDef.x,uDef.z)
			team = gaiaTeamID
			teamString = uDef.team or "gaia"
			if teamString == "human" then
		
				humanTeamList = process(Spring.GetTeamList(),
								function (teamid)
								teamID, leader, isDead, isAiTeam, side, allyTeam, customTeamKeys, incomeMultiplier = Spring.GetTeamInfo(teamid)	
									if teamID and isDead == false and isAiTeam == false then
										return teamid
									end
								end)
				team = humanTeamList[1]
			end
			local flagID = CreateUnit(uDef.name, uDef.x, heigth, uDef.z, 0, team)
			local rotation = uDef.rot or "0"
			if not uDef.rot then rotation = randomStringifyHeading(uDef.rotLow, uDef.rotUp) end
			local unitRotation = (rotation/360) * math.pi*2
			Spring.SetUnitRotation(flagID, 0, unitRotation, 0)
			
			if teamString == "gaia" then
				Spring.SetUnitLosState(flagID,0, losState)
				SetUnitAlwaysVisible(flagID,true)
			end
		end
		
	end
	
	return true
end
return false --unload