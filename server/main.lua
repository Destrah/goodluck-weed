local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('qb-weed:server:getBuildingPlants', function(_, cb, building)
    local buildingPlants = {}

    MySQL.query('SELECT * FROM house_plants WHERE building = ?', {building}, function(plants)
        for i = 1, #plants, 1 do
            buildingPlants[#buildingPlants+1] = plants[i]
        end

        if buildingPlants ~= nil then
            cb(buildingPlants)
        else
            cb(nil)
        end
    end)
end)

AddEventHandler("QBCore:Server:PlayerLoaded", function(xPlayer)
    local _source = xPlayer.PlayerData.source
    TriggerClientEvent('qb-weed-cl:ScriptStart', _source)
end)

QBCore.Functions.CreateCallback('qb-weed:server:getOutsidePlants', function(_, cb)
    MySQL.query('SELECT * FROM outside_plants', {}, function(plants)
        if plants ~= nil then
            cb(plants)
        else
            cb(nil)
        end
    end)
end)

RegisterNetEvent('qb-weed:server:placePlant', function(coords, sort, currentHouse)
    local random = exports['qb-core']:qbRandomNumber(1, 2)
    local gender
    if random == 1 then
        gender = "man"
    else
        gender = "woman"
    end
    local result = exports.oxmysql:query_async('SELECT plantid FROM house_plants', {})
    local randomId = exports['qb-core']:qbRandomNumber(111111, 999999)
    local alreadyExists = true
    while alreadyExists do
        alreadyExists = false
        for i = 1, #result, 1 do
            if result[i].plantid == randomId then
                alreadyExists = true
                randomId = exports['qb-core']:qbRandomNumber(111111, 999999)
                break
            end
        end
    end
    MySQL.insert('INSERT INTO house_plants (building, coords, gender, sort, plantid) VALUES (?, ?, ?, ?, ?)',
        {currentHouse, coords, gender, sort, randomId})
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, currentHouse)
end)

RegisterNetEvent('qb-weed:server:placePlantOutside', function(coords, sort)
    local random = exports['qb-core']:qbRandomNumber(1, 2)
    local gender
    if random == 1 then
        gender = "man"
    else
        gender = "woman"
    end
    local result = exports.oxmysql:query_async('SELECT plantid FROM outside_plants', {})
    local plantid = exports['qb-core']:qbRandomNumber(111111, 999999)
    local alreadyExists = true
    while alreadyExists do
        alreadyExists = false
        for i = 1, #result, 1 do
            if result[i].plantid == plantid then
                alreadyExists = true
                plantid = exports['qb-core']:qbRandomNumber(111111, 999999)
                break
            end
        end
    end
    MySQL.insert('INSERT INTO outside_plants (coords, gender, sort, plantid) VALUES (?, ?, ?, ?)',
        {coords, gender, sort, plantid})
    TriggerClientEvent('qb-weed:client:updateOutsidePlants', -1, coords, gender, sort, plantid)
end)

RegisterNetEvent('qb-weed:server:removeDeathPlant', function(building, plantId)
    MySQL.query('DELETE FROM house_plants WHERE plantid = ? AND building = ?', {plantId, building})
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, building)
end)

RegisterNetEvent('qb-weed:server:removeDeathPlantOutside', function(plantId)
    MySQL.query('DELETE FROM outside_plants WHERE plantid = ?', {plantId})
    TriggerClientEvent('qb-weed:client:refreshOutsidePlants', -1)
end)

RegisterNetEvent("qb-weed-sv:collectEvidenceBag", function(stage, label)
    local _source = source
    local Player = QBCore.Functions.GetPlayer(_source)
    local ped = GetPlayerPed(_source)
    local location = GetEntityCoords(ped)
    local info = {
        label = "Marijuana Plant",
        type = "weed_plant",
        stage = stage,
        plantType = label,
        location = "X: " .. location.x .. "Y: " .. location.y .. "Z: " .. location.z
    }
    if Player.Functions.RemoveItem("empty_evidence_bag", 1, false, {}, true) then
        if not Player.Functions.AddItem("filled_evidence_bag", 1, false, info, true) then return end
    end
end)

CreateThread(function()
    Citizen.Wait(2500)
    TriggerClientEvent('qb-weed-cl:ScriptStart', -1)
end)

CreateThread(function()
    while true do
        local housePlants = MySQL.query.await('SELECT * FROM house_plants', {})
        for k, _ in pairs(housePlants) do
            if housePlants[k].food >= 50 then
                MySQL.update('UPDATE house_plants SET food = ? WHERE plantid = ?',
                    {(housePlants[k].food - 1), housePlants[k].plantid})
                if housePlants[k].health + 1 < 100 then
                    MySQL.update('UPDATE house_plants SET health = ? WHERE plantid = ?',
                        {(housePlants[k].health + 1), housePlants[k].plantid})
                end
            end

            if housePlants[k].food < 50 then
                if housePlants[k].food - 1 >= 0 then
                    MySQL.update('UPDATE house_plants SET food = ? WHERE plantid = ?',
                        {(housePlants[k].food - 1), housePlants[k].plantid})
                end
                if housePlants[k].health - 1 >= 0 then
                    MySQL.update('UPDATE house_plants SET health = ? WHERE plantid = ?',
                        {(housePlants[k].health - 1), housePlants[k].plantid})
                end
            end
        end
        TriggerClientEvent('qb-weed:client:refreshPlantStats', -1)
        Wait((60 * 1000) * 19.2)
    end
end)

CreateThread(function()
    while true do
        local outsidePlants = MySQL.query.await('SELECT * FROM outside_plants', {})
        for k, _ in pairs(outsidePlants) do
            if outsidePlants[k].food >= 50 then
                MySQL.update('UPDATE outside_plants SET food = ? WHERE plantid = ?',
                    {(outsidePlants[k].food - 1), outsidePlants[k].plantid})
                if outsidePlants[k].health + 1 < 100 then
                    MySQL.update('UPDATE outside_plants SET health = ? WHERE plantid = ?',
                        {(outsidePlants[k].health + 1), outsidePlants[k].plantid})
                end
            end

            if outsidePlants[k].food < 50 then
                if outsidePlants[k].food - 1 >= 0 then
                    MySQL.update('UPDATE outside_plants SET food = ? WHERE plantid = ?',
                        {(outsidePlants[k].food - 1), outsidePlants[k].plantid})
                end
                if outsidePlants[k].health - 1 >= 0 then
                    MySQL.update('UPDATE outside_plants SET health = ? WHERE plantid = ?',
                        {(outsidePlants[k].health - 1), outsidePlants[k].plantid})
                end
            end
        end
        TriggerClientEvent('qb-weed:client:refreshPlantStatsOutside', -1)
        Wait((60 * 1000) * 18.2)
    end
end)

CreateThread(function()
    while true do
        local housePlants = MySQL.query.await('SELECT * FROM house_plants', {})
        for k, _ in pairs(housePlants) do
            if housePlants[k].health > 50 then
                local Grow = exports['qb-core']:qbRandomNumber(1, 3)
                if housePlants[k].progress + Grow < 100 then
                    MySQL.update('UPDATE house_plants SET progress = ? WHERE plantid = ?',
                        {(housePlants[k].progress + Grow), housePlants[k].plantid})
                elseif housePlants[k].progress + Grow >= 100 then
                    if housePlants[k].stage ~= QBWeed.Plants[housePlants[k].sort]["highestStage"] then
                        if housePlants[k].stage == "stage-a" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-b', housePlants[k].plantid})
                        elseif housePlants[k].stage == "stage-b" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-c', housePlants[k].plantid})
                        elseif housePlants[k].stage == "stage-c" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-d', housePlants[k].plantid})
                        elseif housePlants[k].stage == "stage-d" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-e', housePlants[k].plantid})
                        elseif housePlants[k].stage == "stage-e" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-f', housePlants[k].plantid})
                        elseif housePlants[k].stage == "stage-f" then
                            MySQL.update('UPDATE house_plants SET stage = ? WHERE plantid = ?',
                                {'stage-g', housePlants[k].plantid})
                        end
                        MySQL.update('UPDATE house_plants SET progress = ? WHERE plantid = ?',
                            {0, housePlants[k].plantid})
                    end
                end
            end
        end
        TriggerClientEvent('qb-weed:client:refreshPlantStats', -1)
        Wait((60 * 1000) * 9.6)
    end
end)

CreateThread(function()
    while true do
        local outsidePlants = MySQL.query.await('SELECT * FROM outside_plants', {})
        for k, _ in pairs(outsidePlants) do
            if outsidePlants[k].health > 50 then
                local Grow = exports['qb-core']:qbRandomNumber(1, 3)
                if outsidePlants[k].progress + Grow < 100 then
                    MySQL.update('UPDATE outside_plants SET progress = ? WHERE plantid = ?',
                        {(outsidePlants[k].progress + Grow), outsidePlants[k].plantid})
                elseif outsidePlants[k].progress + Grow >= 100 then
                    if outsidePlants[k].stage ~= QBWeed.Plants[outsidePlants[k].sort]["highestStage"] then
                        if outsidePlants[k].stage == "stage-a" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-b', outsidePlants[k].plantid})
                        elseif outsidePlants[k].stage == "stage-b" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-c', outsidePlants[k].plantid})
                        elseif outsidePlants[k].stage == "stage-c" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-d', outsidePlants[k].plantid})
                        elseif outsidePlants[k].stage == "stage-d" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-e', outsidePlants[k].plantid})
                        elseif outsidePlants[k].stage == "stage-e" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-f', outsidePlants[k].plantid})
                        elseif outsidePlants[k].stage == "stage-f" then
                            MySQL.update('UPDATE outside_plants SET stage = ? WHERE plantid = ?',
                                {'stage-g', outsidePlants[k].plantid})
                        end
                        MySQL.update('UPDATE outside_plants SET progress = ? WHERE plantid = ?',
                            {0, outsidePlants[k].plantid})
                    end
                end
            end
        end
        TriggerClientEvent('qb-weed:client:refreshPlantStatsOutside', -1)
        Wait((60 * 1000) * 8.2)
    end
end)

QBCore.Functions.CreateUseableItem("weed_white-widow_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'white-widow', item)
end)

QBCore.Functions.CreateUseableItem("weed_skunk_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'skunk', item)
end)

QBCore.Functions.CreateUseableItem("weed_purple-haze_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'purple-haze', item)
end)

QBCore.Functions.CreateUseableItem("weed_og-kush_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'og-kush', item)
end)

QBCore.Functions.CreateUseableItem("weed_amnesia_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'amnesia', item)
end)

QBCore.Functions.CreateUseableItem("weed_ak47_seed", function(source, item)
    TriggerClientEvent('qb-weed:client:placePlant', source, 'ak47', item)
end)

QBCore.Functions.CreateUseableItem("weed_nutrition", function(source, item)
    TriggerClientEvent('qb-weed:client:foodPlant', source, item)
end)

RegisterServerEvent('qb-weed:server:removeSeed', function(itemslot, seed)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(seed, 1, itemslot)
end)

RegisterNetEvent('qb-weed:server:harvestPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local sndAmount = exports['qb-core']:qbRandomNumber(24, 32)

    if weedBag ~= nil then
        if weedBag.amount >= sndAmount then
            if house ~= nil then
                local result = MySQL.query.await(
                    'SELECT * FROM house_plants WHERE plantid = ? AND building = ?', {plantId, house})
                if result[1] ~= nil then
                    Player.Functions.AddItem('weed_' .. plantName .. '_seed', amount, false, {}, true)
                    Player.Functions.AddItem('weed_' .. plantName, sndAmount, false, {}, true)
                    Player.Functions.RemoveItem('empty_weed_bag', sndAmount, false, {}, true)
                    MySQL.query('DELETE FROM house_plants WHERE plantid = ? AND building = ?',
                        {plantId, house})
                    TriggerClientEvent('QBCore:Notify', src,  Lang:t('text.the_plant_has_been_harvested'), 'success', 3500)
                    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, house)
                else
                    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.this_plant_no_longer_exists'), 'error', 3500)
                end
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.house_not_found'), 'error', 3500)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.you_dont_have_enough_resealable_bags'), 'error', 3500)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.you_Dont_have_enough_resealable_bags'), 'error', 3500)
    end
end)

RegisterNetEvent('qb-weed:server:harvestPlantOutside', function(amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local weedBag = Player.Functions.GetItemByName('empty_weed_bag')
    local sndAmount = exports['qb-core']:qbRandomNumber(30, 40)

    if weedBag ~= nil then
        if weedBag.amount >= sndAmount then
            local result = MySQL.query.await(
                'SELECT * FROM outside_plants WHERE plantid = ?', {plantId})
            if result[1] ~= nil then
                Player.Functions.AddItem('weed_' .. plantName .. '_seed', amount, false, {}, true)
                Player.Functions.AddItem('weed_' .. plantName, sndAmount, false, {}, true)
                Player.Functions.RemoveItem('empty_weed_bag', sndAmount, false, {}, true)
                MySQL.query('DELETE FROM outside_plants WHERE plantid = ?',
                    {plantId})
                TriggerClientEvent('QBCore:Notify', src,  Lang:t('text.the_plant_has_been_harvested'), 'success', 3500)
                TriggerClientEvent('qb-weed:client:refreshOutsidePlants', -1)
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.this_plant_no_longer_exists'), 'error', 3500)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.you_dont_have_enough_resealable_bags'), 'error', 3500)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.you_Dont_have_enough_resealable_bags'), 'error', 3500)
    end
end)

RegisterNetEvent('qb-weed:server:foodPlant', function(house, amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plantStats = MySQL.query.await(
        'SELECT * FROM house_plants WHERE building = ? AND sort = ? AND plantid = ?',
        {house, plantName, tostring(plantId)})
    TriggerClientEvent('QBCore:Notify', src,
        QBWeed.Plants[plantName]["label"] .. ' | Nutrition: ' .. plantStats[1].food .. '% + ' .. amount .. '% (' ..
            (plantStats[1].food + amount) .. '%)', 'success', 3500)
    if plantStats[1].food + amount > 100 then
        MySQL.update('UPDATE house_plants SET food = ? WHERE building = ? AND plantid = ?',
            {100, house, plantId})
    else
        MySQL.update('UPDATE house_plants SET food = ? WHERE building = ? AND plantid = ?',
            {(plantStats[1].food + amount), house, plantId})
    end
    Player.Functions.RemoveItem('weed_nutrition', 1)
    TriggerClientEvent('qb-weed:client:refreshHousePlants', -1, house)
end)

RegisterNetEvent('qb-weed:server:foodPlantOutside', function(amount, plantName, plantId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local plantStats = MySQL.query.await(
        'SELECT * FROM outside_plants WHERE sort = ? AND plantid = ?',
        {plantName, tostring(plantId)})
    TriggerClientEvent('QBCore:Notify', src,
        QBWeed.Plants[plantName]["label"] .. ' | Nutrition: ' .. plantStats[1].food .. '% + ' .. amount .. '% (' ..
            (plantStats[1].food + amount) .. '%)', 'success', 3500)
    if plantStats[1].food + amount > 100 then
        MySQL.update('UPDATE outside_plants SET food = ? WHERE plantid = ?',
            {100, plantId})
    else
        MySQL.update('UPDATE outside_plants SET food = ? WHERE plantid = ?',
            {(plantStats[1].food + amount), plantId})
    end
    Player.Functions.RemoveItem('weed_nutrition', 1)
    TriggerClientEvent('qb-weed:client:refreshPlantStatsOutside', -1)
end)

local playersReceieveSeeds = {}

local neededItems = {
    {'milfbustersxxx', 2, 8},
    {'starwarsxxx', 1, 5},
    {'ironmanxxx', 1, 5},
    {'supermanxxx', 2, 5},
}

local typesOfSeeds = {
    {'weed_white-widow_seed', 100},
    {'weed_og-kush_seed', 92},
    {'weed_skunk_seed', 84},
    {'weed_amnesia_seed', 76},
    {'weed_purple-haze_seed', 68},
    {'weed_ak47_seed', 60},
}

RegisterNetEvent("qb-weed-sv:talkToHippy", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local neededItem = nil
    for i = 1, #neededItems, 1 do
        neededItem = Player.Functions.GetItemByName(neededItems[i][1])
        if neededItem ~= nil then
            local random = exports['qb-core']:qbRandomNumber(1, 100)
            local randomSeed = exports['qb-core']:qbRandomNumber(1, #typesOfSeeds)
            local foundSeed = false
            while not foundSeed do
                if random <= typesOfSeeds[randomSeed][2] then
                    foundSeed = true
                else
                    random = exports['qb-core']:qbRandomNumber(1, 100)
                    randomSeed = exports['qb-core']:qbRandomNumber(1, #typesOfSeeds)
                end
                Citizen.Wait(0)
            end
            if playersReceieveSeeds[Player.PlayerData.citizenid] == nil then
                Player.Functions.RemoveItem(neededItem.name, 1, neededItem.slot, neededItem.info, true)
                Player.Functions.AddItem(typesOfSeeds[randomSeed][1], exports['qb-core']:qbRandomNumber(neededItems[i][2], neededItems[i][3]), false, {}, true)
                playersReceieveSeeds[Player.PlayerData.citizenid] = true
            else
                TriggerClientEvent('QBCore:Notify', src, "Sorry man, I can't give you anymore seeds at this time", 'error', 7500)
            end
            break
        end
    end
    if neededItem == nil then
        TriggerClientEvent('QBCore:Notify', src, "Bruh, you ain't got what I need.", 'error', 7500)
    end
end)