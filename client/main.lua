local QBCore = exports['qb-core']:GetCoreObject()
local housePlants = {}
local outsidePlants = {}
local spawnedOutsidePlants = {}
local insideHouse = false
local currentHouse = nil
local plantSpawned = false
local playerLoaded = false
local placingPlant = false
local removingPlant = false
local refreshingPlants = false

local handlingOutside = false
local spawnedOutsideCount = 0

local validPlantingZones = {
    ['Chiliad Mountain State Wilderness'] = true,
    ['Paleto Forest'] = true,
    ['Mount Chiliad'] = true,
    ['Raton Canyon'] = true,
    ['Mount Josiah'] = true,
    ['Mount Gordo'] = true,
    ['San Chianski Mountain Range'] = true,
    ['Cassidy Creek'] = true,
    ['Grand Senora Desert'] = true,
}
local function isValidZone()
    return validPlantingZones[GetLabelText(GetNameOfZone(GetEntityCoords(PlayerPedId())))] == true
end

DrawText3Ds = function(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('qb-weed:server:getOutsidePlants', function(plants)
        outsidePlants = plants
    end)
end)

RegisterNetEvent('qb-weed-cl:ScriptStart', function()
    QBCore.Functions.TriggerCallback('qb-weed:server:getOutsidePlants', function(plants)
        outsidePlants = plants
    end)
end)

Citizen.CreateThread(function()
    while QBCore.Functions.GetPlayerData() == nil do
        Citizen.Wait(0)
    end
    while QBCore.Functions.GetPlayerData().job == nil do
        Citizen.Wait(0)
    end
    outsidePlantHandler()
end)

RegisterNetEvent('qb-weed:client:getHousePlants', function(house)
    QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
        currentHouse = house
        housePlants[currentHouse] = plants
        insideHouse = true
        spawnHousePlants()
    end, house)
end)

function spawnHousePlants()
    CreateThread(function()
        if not plantSpawned then
            for k, _ in pairs(housePlants[currentHouse]) do
                local plantData = {
                    ["plantCoords"] = {["x"] = json.decode(housePlants[currentHouse][k].coords).x, ["y"] = json.decode(housePlants[currentHouse][k].coords).y, ["z"] = json.decode(housePlants[currentHouse][k].coords).z},
                    ["plantProp"] = GetHashKey(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"][housePlants[currentHouse][k].stage]),
                }

                local plantProp = CreateObject(plantData["plantProp"], plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], false, false, false)
                while not plantProp do Wait(0) end
                PlaceObjectOnGroundProperly(plantProp)
                if #(vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]) - GetEntityCoords(plantProp)) >= 0.5 then
                    SetEntityCoords(plantProp, plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"])
                end
                Wait(10)
                FreezeEntityPosition(plantProp, true)
                SetEntityAsMissionEntity(plantProp, true, true)
            end
            plantSpawned = true
        end
    end)
end

function despawnHousePlants()
    CreateThread(function()
        if plantSpawned then
            for k, _ in pairs(housePlants[currentHouse]) do
                local plantData = {
                    ["plantCoords"] = {["x"] = json.decode(housePlants[currentHouse][k].coords).x, ["y"] = json.decode(housePlants[currentHouse][k].coords).y, ["z"] = json.decode(housePlants[currentHouse][k].coords).z},
                }

                for _, stage in pairs(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"]) do
                    local closestPlant = GetClosestObjectOfType(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], 3.5, GetHashKey(stage), false, false, false)
                    if closestPlant ~= 0 then
                        SetEntityAsMissionEntity(plantProp, true, true)
                        DeleteObject(closestPlant)
                    end
                end
            end
            plantSpawned = false
        end
    end)
end

local ClosestTarget = 0

CreateThread(function()
    while true do
        Wait(0)
        if insideHouse then
            if plantSpawned then
                local ped = PlayerPedId()
                for k, _ in pairs(housePlants[currentHouse]) do
                    local gender = "M"
                    if housePlants[currentHouse][k].gender == "woman" then gender = "F" end

                    local plantData = {
                        ["plantCoords"] = {["x"] = json.decode(housePlants[currentHouse][k].coords).x, ["y"] = json.decode(housePlants[currentHouse][k].coords).y, ["z"] = json.decode(housePlants[currentHouse][k].coords).z},
                        ["plantStage"] = housePlants[currentHouse][k].stage,
                        ["plantProp"] = GetHashKey(QBWeed.Plants[housePlants[currentHouse][k].sort]["stages"][housePlants[currentHouse][k].stage]),
                        ["plantSort"] = {
                            ["name"] = housePlants[currentHouse][k].sort,
                            ["label"] = QBWeed.Plants[housePlants[currentHouse][k].sort]["label"],
                        },
                        ["plantStats"] = {
                            ["food"] = housePlants[currentHouse][k].food,
                            ["health"] = housePlants[currentHouse][k].health,
                            ["progress"] = housePlants[currentHouse][k].progress,
                            ["stage"] = housePlants[currentHouse][k].stage,
                            ["highestStage"] = QBWeed.Plants[housePlants[currentHouse][k].sort]["highestStage"],
                            ["gender"] = gender,
                            ["plantId"] = housePlants[currentHouse][k].plantid,
                        }
                    }

                    local plyDistance = #(GetEntityCoords(ped) - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]))

                    if plyDistance < 0.8 then

                        ClosestTarget = k
                        if PlayerJob == "police" then
                            DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"] + 0.2, "Press ~g~ E ~w~ to destroy plant.")
                            DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"],  Lang:t('text.sort')..' ~g~'..closestPlantData["plantSort"]["label"]..'~w~ ['..closestPlantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..closestPlantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..closestPlantData["plantStats"]["health"]..'%')
                            if IsControlJustPressed(0, 38) then
                                if QBCore.Functions.HasItem("shears") then
                                    QBCore.Functions.Progressbar("remove_weed_plant", "Destroying Plant & Bagging Evidence", 8000, false, true, {
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    }, {
                                        animDict = "amb@world_human_gardener_plant@male@base",
                                        anim = "base",
                                        flags = 16,
                                    }, {}, {}, function() -- Done
                                        local ped = PlayerPedId()
                                        ClearPedTasks(ped)
                                        TriggerServerEvent('qb-weed:server:removeDeathPlantOutside', closestPlantData["plantStats"]["plantId"])
                                        if QBCore.Functions.HasItem("empty_evidence_bag") then
                                            TriggerServerEvent("qb-weed-sv:collectEvidenceBag", closestPlantData["plantStage"], closestPlantData["plantSort"]["label"])
                                        else
                                            QBCore.Functions.Notify("You did not collect any evidence due to not having an empty evidence bag.", "error")
                                        end
                                    end, function() -- Cancel
                                        local ped = PlayerPedId()
                                        ClearPedTasks(ped)
                                        QBCore.Functions.Notify("Process Canceled", "error")
                                    end)
                                else
                                    QBCore.Functions.Notify("You need some shears to destroy and bag it into evidence", "error")
                                end
                            end
                        else
                            if plantData["plantStats"]["health"] > 0 then
                                if plantData["plantStage"] ~= plantData["plantStats"]["highestStage"] then
                                    DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"],  Lang:t('text.sort') .. plantData["plantSort"]["label"]..'~w~ ['..plantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..plantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..plantData["plantStats"]["health"]..'%')
                                else
                                    DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"] + 0.2, Lang:t('text.harvest_plant'))
                                    DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"],  Lang:t('text.sort')..' ~g~'..plantData["plantSort"]["label"]..'~w~ ['..plantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..plantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..plantData["plantStats"]["health"]..'%')
                                    if IsControlJustPressed(0, 38) then
                                        QBCore.Functions.Progressbar("remove_weed_plant", Lang:t('text.harvesting_plant'), 8000, false, true, {
                                            disableMovement = true,
                                            disableCarMovement = true,
                                            disableMouse = false,
                                            disableCombat = true,
                                        }, {
                                            animDict = "amb@world_human_gardener_plant@male@base",
                                            anim = "base",
                                            flags = 16,
                                        }, {}, {}, function() -- Done
                                            ClearPedTasks(ped)
                                            local amount = exports['qb-core']:qbRandomNumber(1, 6)
                                            if plantData["plantStats"]["gender"] == "M" then
                                                amount = exports['qb-core']:qbRandomNumber(1, 2)
                                            end
                                            TriggerServerEvent('qb-weed:server:harvestPlant', currentHouse, amount, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                                        end, function() -- Cancel
                                            ClearPedTasks(ped)
                                            QBCore.Functions.Notify("Process Canceled", "error")
                                        end)
                                    end
                                end
                            elseif plantData["plantStats"]["health"] == 0 then
                                DrawText3Ds(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], Lang:t('error.plant_has_died'))
                                if IsControlJustPressed(0, 38) then
                                    QBCore.Functions.Progressbar("remove_weed_plant", Lang:t('text.removing_the_plant'), 8000, false, true, {
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    }, {
                                        animDict = "amb@world_human_gardener_plant@male@base",
                                        anim = "base",
                                        flags = 16,
                                    }, {}, {}, function() -- Done
                                        ClearPedTasks(ped)
                                        TriggerServerEvent('qb-weed:server:removeDeathPlant', currentHouse, plantData["plantStats"]["plantId"])
                                    end, function() -- Cancel
                                        ClearPedTasks(ped)
                                        QBCore.Functions.Notify( Lang:t('error.process_canceled'), "error")
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end

        if not insideHouse then
            Wait(5000)
        end
    end
end)

local closestPlantDist = 200
local closestPlant = nil
local closestPlantData = nil
local PlayerJob

RegisterNetEvent("QBCore:Client:PedLoaded", function()
    outsidePlantHandler()
end)

function outsidePlantHandler()
    if not playerLoaded then
        playerLoaded = true
        Citizen.CreateThread(function()
            while true do
                if not removingPlant and not refreshingPlants and not placingPlant then
                    local tempClosestDist = 200
                    local tempClosestPlant = nil
                    local coords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 0.0, -1.0)
                    for _, info in pairs(spawnedOutsidePlants) do
                        if #(coords - info[1]) < tempClosestDist then
                            tempClosestDist = #(coords - info[1])
                            tempClosestPlant = info[3]
                        end
                    end
                    if tempClosestDist < 2.2 then
                        closestPlant = tempClosestPlant
                        closestPlantDist = tempClosestDist
                        local gender = "M"
                        if outsidePlants[closestPlant].gender == "woman" then gender = "F" end
                        closestPlantData = {
                            ["plantCoords"] = {["x"] = json.decode(outsidePlants[closestPlant].coords).x, ["y"] = json.decode(outsidePlants[closestPlant].coords).y, ["z"] = (json.decode(outsidePlants[closestPlant].coords).z + 1.55)},
                            ["plantStage"] = outsidePlants[closestPlant].stage,
                            ["plantProp"] = GetHashKey(QBWeed.Plants[outsidePlants[closestPlant].sort]["stages"][outsidePlants[closestPlant].stage]),
                            ["plantSort"] = {
                                ["name"] = outsidePlants[closestPlant].sort,
                                ["label"] = QBWeed.Plants[outsidePlants[closestPlant].sort]["label"],
                            },
                            ["plantStats"] = {
                                ["food"] = outsidePlants[closestPlant].food,
                                ["health"] = outsidePlants[closestPlant].health,
                                ["progress"] = outsidePlants[closestPlant].progress,
                                ["stage"] = outsidePlants[closestPlant].stage,
                                ["highestStage"] = QBWeed.Plants[outsidePlants[closestPlant].sort]["highestStage"],
                                ["gender"] = gender,
                                ["plantId"] = outsidePlants[closestPlant].plantid,
                            }
                        }
                    else
                        closestPlant = nil
                    end
                end
                Citizen.Wait(350)
            end
        end)
        Citizen.CreateThread(function()
            while true do
                PlayerJob = QBCore.Functions.GetPlayerData().job.name
                local coords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 0.0, -1.0)
                if not removingPlant and not refreshingPlants and not placingPlant then
                    for _, info in pairs(outsidePlants) do
                        local plantData = {
                            ["plantCoords"] = {["x"] = json.decode(info.coords).x, ["y"] = json.decode(info.coords).y, ["z"] = json.decode(info.coords).z},
                            ["plantProp"] = GetHashKey(QBWeed.Plants[info.sort]["stages"][info.stage]),
                        }
                        local spawnedPlant = false
                        --for i = #spawnedOutsidePlants, 1, -1 do\
                        if spawnedOutsidePlants[info.plantid] ~= nil and not removingPlant and not refreshingPlants and not placingPlant and spawnedOutsideCount > 0 then
                            if #(spawnedOutsidePlants[info.plantid][1] - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"])) <= 0.4 then
                                local ped, distance = QBCore.Functions.GetClosestObjectFilter(spawnedOutsidePlants[info.plantid][2], spawnedOutsidePlants[info.plantid][1])
                                if GetEntityModel(ped) == GetHashKey(spawnedOutsidePlants[info.plantid][2]) then
                                    if #(coords - spawnedOutsidePlants[info.plantid][1]) > 125.0 and distance <= 1.05 and ped ~= 0 then
                                        while(DoesEntityExist(ped)) do
                                            SetEntityAsMissionEntity(ped, false, true)
                                            DeleteEntity(ped)
                                            SetEntityAsNoLongerNeeded(ped)
                                            Citizen.Wait(0)
                                        end
                                        spawnedOutsidePlants[info.plantid] = nil
                                        spawnedOutsideCount = spawnedOutsideCount - 1
                                        if spawnedOutsideCount == 0 then
                                            handlingOutside = false
                                        end
                                    elseif distance <= 2.0 then
                                        spawnedOutsidePlants[info.plantid][3] = _
                                        spawnedPlant = true
                                    elseif distance > 2.0 then
                                        spawnedOutsidePlants[info.plantid] = nil
                                        spawnedOutsideCount = spawnedOutsideCount - 1
                                        if spawnedOutsideCount == 0 then
                                            handlingOutside = false
                                        end
                                    end
                                else
                                    spawnedOutsidePlants[info.plantid] = nil
                                    spawnedOutsideCount = spawnedOutsideCount - 1
                                    if spawnedOutsideCount == 0 then
                                        handlingOutside = false
                                    end
                                end
                            end
                        elseif #(coords - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"])) <= 125.0 and not spawnedPlant and not removingPlant and not refreshingPlants and not placingPlant then
                            RequestModel(plantData["plantProp"])
                
                            while not HasModelLoaded(plantData["plantProp"]) do
                                Wait(1)
                            end
                            local plantProp = CreateObject(plantData["plantProp"], plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"], false, false, false)
                            while not plantProp do Wait(0) end
                            PlaceObjectOnGroundProperly(plantProp)
                            Citizen.Wait(10)
                            local offset = GetOffsetFromEntityInWorldCoords(plantProp, 0.0, 0.0, -0.45)
                            local rotation = GetEntityRotation(plantProp)
                            SetEntityCoords(plantProp, offset, false, false, false, false)
                            SetEntityRotation(plantProp, rotation, 1, true)
                            FreezeEntityPosition(plantProp, true)
                            SetEntityInvincible(plantProp, true)
                            handleOutsideKeyPresses()
                            spawnedOutsidePlants[info.plantid] = {vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]), QBWeed.Plants[info.sort]["stages"][info.stage], _, false, plantProp}
                            spawnedOutsideCount = spawnedOutsideCount + 1
                        end
                        Citizen.Wait(0)
                    end
                end
                Citizen.Wait(700)
            end
        end)
    end
end

function handleOutsideKeyPresses()
    Citizen.CreateThread(function()
        if not handlingOutside then
            handlingOutside = true
            while handlingOutside do
                if closestPlant ~= nil then
                    if closestPlantDist < 2.2 then
                        ClosestTarget = closestPlant
                        if PlayerJob == "police" then
                            DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"] + 0.2, "Press ~g~ E ~w~ to destroy plant.")
                            DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"],  Lang:t('text.sort')..' ~g~'..closestPlantData["plantSort"]["label"]..'~w~ ['..closestPlantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..closestPlantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..closestPlantData["plantStats"]["health"]..'%')
                            if IsControlJustPressed(0, 38) then
                                if QBCore.Functions.HasItem("shears") then
                                    QBCore.Functions.Progressbar("remove_weed_plant", "Destroying Plant & Bagging Evidence", 8000, false, true, {
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    }, {
                                        animDict = "amb@world_human_gardener_plant@male@base",
                                        anim = "base",
                                        flags = 16,
                                    }, {}, {}, function() -- Done
                                        local ped = PlayerPedId()
                                        ClearPedTasks(ped)
                                        TriggerServerEvent('qb-weed:server:removeDeathPlantOutside', closestPlantData["plantStats"]["plantId"])
                                        if QBCore.Functions.HasItem("empty_evidence_bag") then
                                            TriggerServerEvent("qb-weed-sv:collectEvidenceBag", closestPlantData["plantStage"], closestPlantData["plantSort"]["label"])
                                        else
                                            QBCore.Functions.Notify("You did not collect any evidence due to not having an empty evidence bag.", "error")
                                        end
                                    end, function() -- Cancel
                                        local ped = PlayerPedId()
                                        ClearPedTasks(ped)
                                        QBCore.Functions.Notify("Process Canceled", "error")
                                    end)
                                else
                                    QBCore.Functions.Notify("You need some shears to destroy and bag it into evidence", "error")
                                end
                            end
                        else
                            if closestPlantData["plantStats"]["health"] > 0 then
                                if closestPlantData["plantStage"] ~= closestPlantData["plantStats"]["highestStage"] then
                                    DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"],  Lang:t('text.sort') .. closestPlantData["plantSort"]["label"]..'~w~ ['..closestPlantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..closestPlantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..closestPlantData["plantStats"]["health"]..'%')
                                else
                                    DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"] + 0.2, Lang:t('text.harvest_plant'))
                                    DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"],  Lang:t('text.sort')..' ~g~'..closestPlantData["plantSort"]["label"]..'~w~ ['..closestPlantData["plantStats"]["gender"]..'] | '..Lang:t('text.nutrition')..' ~b~'..closestPlantData["plantStats"]["food"]..'% ~w~ | '..Lang:t('text.health')..' ~b~'..closestPlantData["plantStats"]["health"]..'%')
                                    if IsControlJustPressed(0, 38) then
                                        if QBCore.Functions.HasItem("shears") then
                                            removingPlant = true
                                            QBCore.Functions.Progressbar("remove_weed_plant", Lang:t('text.harvesting_plant'), exports['qb-core']:qbRandomNumber(3500, 6500), false, true, {
                                                disableMovement = true,
                                                disableCarMovement = true,
                                                disableMouse = false,
                                                disableCombat = true,
                                            }, {
                                                animDict = "amb@world_human_gardener_plant@male@base",
                                                anim = "base",
                                                flags = 16,
                                            }, {}, {}, function() -- Done
                                                local ped = PlayerPedId()
                                                ClearPedTasks(ped)
                                                local amount = exports['qb-core']:qbRandomNumber(1, 6)
                                                if closestPlantData["plantStats"]["gender"] == "M" then
                                                    amount = exports['qb-core']:qbRandomNumber(1, 2)
                                                end
                                                TriggerServerEvent('qb-weed:server:harvestPlantOutside', amount, closestPlantData["plantSort"]["name"], closestPlantData["plantStats"]["plantId"])
                                                Citizen.CreateThread(function()
                                                    Citizen.Wait(250)
                                                    removingPlant = false
                                                end)
                                            end, function() -- Cancel
                                                local ped = PlayerPedId()
                                                ClearPedTasks(ped)
                                                QBCore.Functions.Notify("Process Canceled", "error")
                                                Citizen.CreateThread(function()
                                                    Citizen.Wait(250)
                                                    removingPlant = false
                                                end)
                                            end)
                                        else
                                            QBCore.Functions.Notify("You need some shears to harvest the plant", "error")
                                        end
                                    end
                                end
                            elseif closestPlantData["plantStats"]["health"] == 0 then
                                DrawText3Ds(closestPlantData["plantCoords"]["x"], closestPlantData["plantCoords"]["y"], closestPlantData["plantCoords"]["z"], Lang:t('error.plant_has_died'))
                                if IsControlJustPressed(0, 38) then
                                    if QBCore.Functions.HasItem("shears") then
                                        QBCore.Functions.Progressbar("remove_weed_plant", Lang:t('text.removing_the_plant'), 8000, false, true, {
                                            disableMovement = true,
                                            disableCarMovement = true,
                                            disableMouse = false,
                                            disableCombat = true,
                                        }, {
                                            animDict = "amb@world_human_gardener_plant@male@base",
                                            anim = "base",
                                            flags = 16,
                                        }, {}, {}, function() -- Done
                                            local ped = PlayerPedId()
                                            ClearPedTasks(ped)
                                            TriggerServerEvent('qb-weed:server:removeDeathPlantOutside', closestPlantData["plantStats"]["plantId"])
                                        end, function() -- Cancel
                                            local ped = PlayerPedId()
                                            ClearPedTasks(ped)
                                            QBCore.Functions.Notify( Lang:t('error.process_canceled'), "error")
                                        end)
                                    else
                                        QBCore.Functions.Notify("You need some shears to remoe the dead plant", "error")
                                    end
                                end
                            end
                        end
                    end
                    Citizen.Wait(0)
                else
                    Citizen.Wait(1000)
                end
            end
        end
    end)
end

RegisterNetEvent('qb-weed:client:leaveHouse', function()
    despawnHousePlants()
    SetTimeout(1000, function()
        if currentHouse ~= nil then
            insideHouse = false
            housePlants[currentHouse] = nil
            currentHouse = nil
        end
    end)
end)

RegisterNetEvent('qb-weed:client:refreshHousePlants', function(house)
    if currentHouse ~= nil and currentHouse == house then
        despawnHousePlants()
        SetTimeout(100, function()
            QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
                currentHouse = house
                housePlants[currentHouse] = plants
                spawnHousePlants()
            end, house)
        end)
    end
end)

RegisterNetEvent('qb-weed:client:refreshOutsidePlants', function()
    refreshingPlants = true
    if spawnedOutsideCount > 0 then
        QBCore.Functions.TriggerCallback('qb-weed:server:getOutsidePlants', function(plants)
            outsidePlants = plants
            for _, info in pairs(outsidePlants) do
                if spawnedOutsidePlants[info.plantid] ~= nil then
                    local plantData = {
                        ["plantCoords"] = {["x"] = json.decode(info.coords).x, ["y"] = json.decode(info.coords).y, ["z"] = json.decode(info.coords).z},
                        ["plantProp"] = GetHashKey(QBWeed.Plants[info.sort]["stages"][info.stage]),
                    }
                    if #(spawnedOutsidePlants[info.plantid][1] - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"])) <= 0.1 then
                        local ped = spawnedOutsidePlants[info.plantid][5]
                        if GetEntityModel(ped) ~= plantData.plantProp then
                            while(DoesEntityExist(ped)) do
                                SetEntityAsMissionEntity(ped, true, true)
                                DeleteEntity(ped)
                                SetEntityAsNoLongerNeeded(ped)
                                Citizen.Wait(100)
                            end
                            spawnedOutsidePlants[info.plantid] = nil
                            spawnedOutsidePlants[info.plantid][4] = false
                            spawnedOutsideCount = spawnedOutsideCount - 1
                            if spawnedOutsideCount == 0 then
                                handlingOutside = false
                            end
                        else
                            spawnedOutsidePlants[info.plantid][3] = _
                            spawnedOutsidePlants[info.plantid][4] = true
                        end
                    end
                end
            end
            for id, info in pairs(spawnedOutsidePlants) do
                if info[4] == nil or info[4] == false then
                    local ped = info[5]
                    while(DoesEntityExist(ped)) do
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                        SetEntityAsNoLongerNeeded(ped)
                        Citizen.Wait(0)
                    end
                    spawnedOutsidePlants[id] = nil
                else
                    spawnedOutsidePlants[id][4] = false
                end
            end
            refreshingPlants = false
        end)
    else
        refreshingPlants = false
    end
end)

RegisterNetEvent('qb-weed:client:updateOutsidePlants', function(coords, gender, sort, plantid)
    local plantData = {
        ["coords"] = coords,
        ["food"] = 100,
        ["health"] = 100,
        ["progress"] = 0,
        ["stage"] = "stage-a",
        ["highestStage"] = QBWeed.Plants[sort]["highestStage"],
        ["gender"] = gender,
        ["plantid"] = plantid,
        ["sort"] = sort
    }
    table.insert(outsidePlants, plantData)
end)

RegisterNetEvent('qb-weed:client:refreshPlantStats', function()
    if insideHouse then
        despawnHousePlants()
        SetTimeout(100, function()
            QBCore.Functions.TriggerCallback('qb-weed:server:getBuildingPlants', function(plants)
                housePlants[currentHouse] = plants
                spawnHousePlants()
            end, currentHouse)
        end)
    end
end)

RegisterNetEvent('qb-weed:client:refreshPlantStatsOutside', function()
    refreshingPlants = true
    if spawnedOutsideCount > 0 then
        QBCore.Functions.TriggerCallback('qb-weed:server:getOutsidePlants', function(plants)
            outsidePlants = plants
            for _, info in pairs(outsidePlants) do
                if spawnedOutsidePlants[info.plantid] ~= nil then
                    local plantData = {
                        ["plantCoords"] = {["x"] = json.decode(info.coords).x, ["y"] = json.decode(info.coords).y, ["z"] = json.decode(info.coords).z},
                        ["plantProp"] = GetHashKey(QBWeed.Plants[info.sort]["stages"][info.stage]),
                    }
                    if #(spawnedOutsidePlants[info.plantid][1] - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"])) <= 0.1 then
                        local ped = spawnedOutsidePlants[info.plantid][5]
                        if GetEntityModel(ped) ~= plantData.plantProp then
                            while(DoesEntityExist(ped)) do
                                SetEntityAsMissionEntity(ped, true, true)
                                DeleteEntity(ped)
                                SetEntityAsNoLongerNeeded(ped)
                                Citizen.Wait(100)
                            end
                            spawnedOutsidePlants[info.plantid] = nil
                            spawnedOutsidePlants[info.plantid][4] = false
                            spawnedOutsideCount = spawnedOutsideCount - 1
                            if spawnedOutsideCount == 0 then
                                handlingOutside = false
                            end
                        else
                            spawnedOutsidePlants[info.plantid][3] = _
                            spawnedOutsidePlants[info.plantid][4] = true
                        end
                    end
                end
            end
            for id, info in pairs(spawnedOutsidePlants) do
                if info[4] == nil or info[4] == false then
                    local ped = info[5]
                    while(DoesEntityExist(ped)) do
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                        SetEntityAsNoLongerNeeded(ped)
                        Citizen.Wait(0)
                    end
                    spawnedOutsidePlants[id] = nil
                else
                    spawnedOutsidePlants[id][4] = false
                end
            end
            refreshingPlants = false
        end)
    else
        refreshingPlants = false
    end
end)

local lastPlanted = 0

RegisterNetEvent('qb-weed:client:placePlant', function(type, item)
    local ped = PlayerPedId()
    local ClosestPlant = 0
    local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -0.45)
    if (GetGameTimer() - lastPlanted) > 3000 then
        for _, v in pairs(QBWeed.Props) do
            if ClosestPlant == 0 then
                ClosestPlant = GetClosestObjectOfType(plyCoords.x, plyCoords.y, plyCoords.z, 0.8, GetHashKey(v), false, false, false)
            end
        end
        if currentHouse ~= nil then
            if ClosestPlant == 0 then
                if QBCore.Functions.HasItem("pot") then
                    local plantData = {
                        ["plantCoords"] = {["x"] = plyCoords.x, ["y"] = plyCoords.y, ["z"] = (plyCoords.z)},
                        ["plantModel"] = QBWeed.Plants[type]["stages"]["stage-a"],
                        ["plantLabel"] = QBWeed.Plants[type]["label"]
                    }
                    LocalPlayer.state:set("inv_busy", true, true)
                    QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.planting'), 5000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@world_human_gardener_plant@male@base",
                        anim = "base",
                        flags = 16,
                    }, {}, {}, function() -- Done
                        lastPlanted = GetGameTimer()
                        ClearPedTasks(ped)
                        TriggerServerEvent('qb-weed:server:placePlant', json.encode(plantData["plantCoords"]), type, currentHouse)
                        TriggerServerEvent('qb-weed:server:removeSeed', item.slot, type)
                        TriggerServerEvent("qb-inventory-sv:RemoveItem", "pot", 1, false, true)
                        LocalPlayer.state:set("inv_busy", false, true)

                    end, function() -- Cancel
                        ClearPedTasks(ped)
                        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
                        LocalPlayer.state:set("inv_busy", false, true)
                    end)
                else
                    QBCore.Functions.Notify("You need a pot to plant that in", 'error', 3500)
                end
            else
                QBCore.Functions.Notify(Lang:t('error.cant_place_here'), 'error', 3500)
            end
        elseif isValidZone() then
            if ClosestPlant == 0 then
                if QBCore.Functions.HasItem("shovel") then
                    placingPlant = true
                    local plantData = {
                        ["plantCoords"] = {["x"] = plyCoords.x, ["y"] = plyCoords.y, ["z"] = (plyCoords.z - 1.45)},
                        ["plantModel"] = QBWeed.Plants[type]["stages"]["stage-a"],
                        ["plantLabel"] = QBWeed.Plants[type]["label"]
                    }
                    LocalPlayer.state:set("inv_busy", true, true)
                    QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.planting'), 4500, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@world_human_gardener_plant@male@base",
                        anim = "base",
                        flags = 16,
                        LocalPlayer.state:set("inv_busy", false, true)
                    }, {}, {}, function() -- Done
                        lastPlanted = GetGameTimer()
                        ClearPedTasks(ped)
                        TriggerServerEvent('qb-weed:server:placePlantOutside', json.encode(plantData["plantCoords"]), type)
                        TriggerServerEvent('qb-weed:server:removeSeed', item.slot, type)
                        Citizen.CreateThread(function()
                            Citizen.Wait(250)
                            placingPlant = false
                        end)
                    end, function() -- Cancel
                        ClearPedTasks(ped)
                        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
                        LocalPlayer.state:set("inv_busy", false, true)
                        Citizen.CreateThread(function()
                            Citizen.Wait(250)
                            placingPlant = false
                        end)
                    end)
                else
                    QBCore.Functions.Notify("You need to a shovel to plant that outside", 'error', 3500)
                end
            else
                QBCore.Functions.Notify(Lang:t('error.cant_place_here'), 'error', 3500)
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_safe_here'), 'error', 3500)
        end
    else
        QBCore.Functions.Notify("You need to wait 3 seconds after planting before planint another", 'error', 3500)
    end
end)

RegisterNetEvent('qb-weed:client:foodPlant', function()
    if currentHouse ~= nil then
        if ClosestTarget ~= 0 then
            local ped = PlayerPedId()
            local gender = "M"
            if housePlants[currentHouse][ClosestTarget].gender == "woman" then
                gender = "F"
            end

            local plantData = {
                ["plantCoords"] = {["x"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).x, ["y"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).y, ["z"] = json.decode(housePlants[currentHouse][ClosestTarget].coords).z},
                ["plantStage"] = housePlants[currentHouse][ClosestTarget].stage,
                ["plantProp"] = GetHashKey(QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["stages"][housePlants[currentHouse][ClosestTarget].stage]),
                ["plantSort"] = {
                    ["name"] = housePlants[currentHouse][ClosestTarget].sort,
                    ["label"] = QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["label"],
                },
                ["plantStats"] = {
                    ["food"] = housePlants[currentHouse][ClosestTarget].food,
                    ["health"] = housePlants[currentHouse][ClosestTarget].health,
                    ["progress"] = housePlants[currentHouse][ClosestTarget].progress,
                    ["stage"] = housePlants[currentHouse][ClosestTarget].stage,
                    ["highestStage"] = QBWeed.Plants[housePlants[currentHouse][ClosestTarget].sort]["highestStage"],
                    ["gender"] = gender,
                    ["plantId"] = housePlants[currentHouse][ClosestTarget].plantid,
                }
            }
            local plyDistance = #(GetEntityCoords(ped) - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]))

            if plyDistance < 1.0 then
                if plantData["plantStats"]["food"] == 100 then
                    QBCore.Functions.Notify(Lang:t('error.not_need_nutrition'), 'error', 3500)
                else
		            LocalPlayer.state:set("inv_busy", true, true)
                    QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.feeding_plant'), exports['qb-core']:qbRandomNumber(4000, 8000), false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "timetable@gardener@filling_can",
                        anim = "gar_ig_5_filling_can",
                        flags = 16,

                        LocalPlayer.state:set("inv_busy", false, true)
                    }, {}, {}, function() -- Done
                        ClearPedTasks(ped)
                        local newFood = exports['qb-core']:qbRandomNumber(40, 60)
                        TriggerServerEvent('qb-weed:server:foodPlant', currentHouse, newFood, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                    end, function() -- Cancel
                        ClearPedTasks(ped)
			            LocalPlayer.state:set("inv_busy", false, true)
                        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
                    end)
                end
            else
                QBCore.Functions.Notify(Lang:t('error.cant_place_here'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.cant_place_here'), "error")
        end
    else
        if ClosestTarget ~= 0 then
            local ped = PlayerPedId()
            local gender = "M"
            if outsidePlants[ClosestTarget].gender == "woman" then
                gender = "F"
            end

            local plantData = {
                ["plantCoords"] = {["x"] = json.decode(outsidePlants[ClosestTarget].coords).x, ["y"] = json.decode(outsidePlants[ClosestTarget].coords).y, ["z"] = (json.decode(outsidePlants[ClosestTarget].coords).z + 1.55)},
                ["plantStage"] = outsidePlants[ClosestTarget].stage,
                ["plantProp"] = GetHashKey(QBWeed.Plants[outsidePlants[ClosestTarget].sort]["stages"][outsidePlants[ClosestTarget].stage]),
                ["plantSort"] = {
                    ["name"] = outsidePlants[ClosestTarget].sort,
                    ["label"] = QBWeed.Plants[outsidePlants[ClosestTarget].sort]["label"],
                },
                ["plantStats"] = {
                    ["food"] = outsidePlants[ClosestTarget].food,
                    ["health"] = outsidePlants[ClosestTarget].health,
                    ["progress"] = outsidePlants[ClosestTarget].progress,
                    ["stage"] = outsidePlants[ClosestTarget].stage,
                    ["highestStage"] = QBWeed.Plants[outsidePlants[ClosestTarget].sort]["highestStage"],
                    ["gender"] = gender,
                    ["plantId"] = outsidePlants[ClosestTarget].plantid,
                }
            }
            local plyDistance = #(GetEntityCoords(ped) - vector3(plantData["plantCoords"]["x"], plantData["plantCoords"]["y"], plantData["plantCoords"]["z"]))

            if plyDistance < 1.0 then
                if plantData["plantStats"]["food"] == 100 then
                    QBCore.Functions.Notify(Lang:t('error.not_need_nutrition'), 'error', 3500)
                else
		            LocalPlayer.state:set("inv_busy", true, true)
                    QBCore.Functions.Progressbar("plant_weed_plant", Lang:t('text.feeding_plant'), exports['qb-core']:qbRandomNumber(2000, 6000), false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "timetable@gardener@filling_can",
                        anim = "gar_ig_5_filling_can",
                        flags = 16,

                        LocalPlayer.state:set("inv_busy", false, true)
                    }, {}, {}, function() -- Done
                        ClearPedTasks(ped)
                        local newFood = exports['qb-core']:qbRandomNumber(40, 60)
                        TriggerServerEvent('qb-weed:server:foodPlantOutside', newFood, plantData["plantSort"]["name"], plantData["plantStats"]["plantId"])
                    end, function() -- Cancel
                        ClearPedTasks(ped)
			            LocalPlayer.state:set("inv_busy", false, true)
                        QBCore.Functions.Notify(Lang:t('error.process_canceled'), "error")
                    end)
                end
            else
                QBCore.Functions.Notify(Lang:t('error.cant_place_here'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.cant_place_here'), "error")
        end
    end
end)
