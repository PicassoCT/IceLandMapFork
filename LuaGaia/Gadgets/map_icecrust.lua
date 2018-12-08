

--- - file: Land_Lord.lua
-- brief: spawns start unit and sets storage levels
-- author: Andrea Piras
--
-- Copyright (C) 2010,2011.
-- Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "LandLord ",
        desc = "Recives the terraFormInformation. applies the actuall terraforming, informs Units about the currentWaterLevelOffset",
        author = "PicassoCT",
        date = "7 b.Creation",
        license = "GNU GPL, v2 its goes in all fields",
        layer = 0,
        enabled = true -- loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (gadgetHandler:IsSyncedCode()) then
    VFS.Include('scripts/lib_UnitScript.lua', nil, VFSMODE)

    GG.boolForceLandLordUpdate = false
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------


    local gWaterOffSet = 0 --global WaterOffset
    local UPDATE_FREQUNECY = 4200
    local increaseRate = 0.01 --reSetMe to 0.001
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    boolFirst = true

    --Table contains all the WaterLevelChanging Units
    local WaterLevelChangingUnitsTable = {}
    --Table contains all Units who perform Terraforming - and thus need to be informed of rising waterLevels
    local LandLordTable = {}

    orgTerrainMap = {}
    GroundDeformation = {}
    futureMapSize = 54
  

    --Creates the original TerrainTable
    local MapSizeX = Game.mapSizeX / 8
    local MapSizeZ = Game.mapSizeZ / 8
    sizeMattersX = (Game.mapSizeX) / 8
    sizeMattersZ = (Game.mapSizeZ) / 8

    function forgeFirstTerrainMap() 
        local spGetGroundHeight = Spring.GetGroundHeight

        for out = 1, sizeMattersX, 1 do
            SubTable = {}

            for i = 1, sizeMattersZ, 1 do
                --startCaseExtra
                if i ~= 1 and out ~= 1 then
                    SubTable[i + 1] = spGetGroundHeight(out * 8, i * 8)
                elseif i == 1 and out ~= 1 then
                    SubTable[1] = spGetGroundHeight(out * 8, 1)
                    SubTable[2] = spGetGroundHeight(out * 8, 8)
                elseif out == 1 and i ~= 1 then
                    SubTable[i + 1] = spGetGroundHeight(1, i * 8)
                else
                    SubTable[i] = spGetGroundHeight(1, 1)
                end
            end

            if out ~= 1 then
                orgTerrainMap[out + 1] = SubTable
            else
                orgTerrainMap[1] = SubTable
            end
        end
  
    end





    function determinateTileNrZ(tileNr) --rewritten
        if tileNr > 0 and tileNr < 9 then
            return 1
        elseif tileNr > 8 and tileNr < 17 then
            return 2
        elseif tileNr > 16 and tileNr < 25 then
            return 3
        elseif tileNr > 24 and tileNr < 33 then
            return 4
        elseif tileNr > 32 and tileNr < 41 then
            return 5
        elseif tileNr > 40 and tileNr < 49 then
            return 6
        elseif tileNr > 48 and tileNr < 57 then
            return 7
        else
            return 8
        end
    end

    -- function round

    tileSizeX = (MapSizeX) / 8
    tileSizeZ = (MapSizeZ) / 8


    MapSizeXDiv8 = math.floor(MapSizeX) / 8
    MapSizeZDiv8 = math.floor(MapSizeZ) / 8




    --rewritten
    LDtileSizeX = (MapSizeX)
    LDtileSizeZ = (MapSizeZ)
    function loadDistributor(tileNr, WaterOffset)
        --1
        --preparations
        tileCoordX = tileNr % 8 --from 1 to 64
        if tileCoordX == 0 then tileCoordX = 8 end

        --tileCoordX=1

        tileCoordZ = determinateTileNrZ(tileNr)
        --tileCoordZ=1
        --Spring.Echo("JWL_X-Coord Number"..tileCoordX .."of Tile Nr:"..tileNr)
        --Spring.Echo("JWL_rounded Number"..tileCoordZ .."of Tile Nr:"..tileNr)
        --Spring.Echo("JWL_sizeOfOrgTerrainMap",table.getn(orgTerrainMap))
        --secondstage
        startVarX = ((tileCoordX - 1) * LDtileSizeX) + 1
        endVarX = startVarX + LDtileSizeX - 1
        --endVarX=127
        startVarZ = ((tileCoordZ - 1) * LDtileSizeZ) + 1
        endVarZ = startVarZ + LDtileSizeZ - 1
        --endVarZ=127
        ------------------------------------ TestEchos---------------------
        local cceil = math.ceil
        if (endVarZ >= MapSizeZ * 8) then
            endVarZ = MapSizeZ * 8 - 1
        end
        if (endVarX >= MapSizeX * 8) then
            endVarX = MapSizeX * 8 - 1
        end
        --Echos the Start And EndVariables
        --Spring.Echo("StarVarX:"..startVarX .."EndVarX:"..endVarX)
        --Spring.Echo("StarVarZ:"..startVarZ .."EndVarZ:"..endVarZ)
        --Testing by spawing a ceg in every square
        --Effect

        -- pointY=Spring.GetGroundHeight(startVarX,startVarZ)
        -- teamID = Spring.GetGaiaTeamID ()
        --		mexID= Spring.CreateUnit("zombie", startVarX, pointY, startVarZ, 0, teamID)
        --
        local spSetHeightMapFunc = Spring.SetHeightMapFunc
        ------------------------------------ /TestEchos---------------------
        -- the actuall loop


        spSetHeightMapFunc(function()
            local spSetHeightMap = Spring.SetHeightMap
            local wOffset = WaterOffset
            --1, 127
            for z = startVarZ, endVarZ, 8 do
                boolPulledOff = false
                for x = startVarX, endVarX, 8 do --changed to 8 as the wizzard zwzsg said i should ;)

                    if not orgTerrainMap[cceil(x / 8)] or not orgTerrainMap[cceil(x / 8)][cceil(z / 8)] then Spring.Echo("JW::LANDLORD:: No orgTerrainMap @" .. cceil(x / 8) .. " / " .. cceil(z / 8))
        
                    end

                    if orgTerrainMap[cceil(x / 8)] and orgTerrainMap[cceil(x / 8)][cceil(z / 8)] then
                        spSetHeightMap(x, z, orgTerrainMap[cceil(x / 8)][cceil(z / 8)] + wOffset)
                        boolPulledOff = true
                    end
                 end
             end
        end)
    end


    local boolForceUpdateFlag = false
    local WaterOffsetMain = 0
    local boolOneAndOnly = true
    function gadget:GameFrame(f)

    


        if f % UPDATE_FREQUNECY == 0  or boolOneAndOnly == true then
            boolForceUpdateFlag = false
            --update the MapExtremas
            updateMaxima()
            if boolOneAndOnly  then
                boolOneAndOnly = nil

                forgeFirstTerrainMap()
            end

            --increment the depletion Percentage
            --applyChanges to Map

            TerraInFormTable()

            WaterOffsetMain = getGlobalOffset()

        end

        --by now we have the global HeightMap stored in the TerrainMapWorkingCopy
        if f % UPDATE_FREQUNECY > 0 and f % UPDATE_FREQUNECY < 66 then

            --Spring.Echo("JWL_LoadDistributor working on PieceNr:".. (f%UPDATE_FREQUNECY) .."of 64")
            --this function distributes the terraforming workload into 64 equal parts - each frame taking one part
            loadDistributor(((f % UPDATE_FREQUNECY)), WaterOffsetMain)
        end
    end
end
