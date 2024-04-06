local bannedVehicles = {
    "deluxo",
    "jet",
    "cargoplane",
    "khanjali",
    "rhino",
    "kuruma2",
    "oppressor",
    "oppressor2",
    "hydra",
    "lazer",
    "tug",
    "kosatka", -- Pelda tiltott jarmu: deluxo
    -- Tovabbi tiltott jarmuvek itt felsorolva
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Ellenőrzés minden másodpercben

        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if DoesEntityExist(vehicle) then
            local model = GetEntityModel(vehicle)
            local modelName = GetDisplayNameFromVehicleModel(model)
            
            for _, bannedVehicle in ipairs(bannedVehicles) do
                if string.lower(modelName) == bannedVehicle then
                    TriggerServerEvent('kickPlayer', GetPlayerServerId(NetworkGetEntityOwner(vehicle)))
                    
                    -- Törlés az összes járműről a játékos körül egy 100 méteres körzetben
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    local vehicles = ESX.Game.GetVehiclesInArea(coords, 100.0)
                    for _, vehicleNearby in ipairs(vehicles) do
                        DeleteVehicle(vehicleNearby)
                    end

                    DeleteVehicle(vehicle)
                    break
                end
            end
        end
    end
end)

