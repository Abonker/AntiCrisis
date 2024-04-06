local bannedVehicles = {
    "deluxo",
    "jet",
    "cargoplane",
    "khanjali",
    "rhino",
    "kuruma2",
    "hydra",
    "lazer",
    "tug",
    "kosatka", -- Példa tiltott jármű: deluxo
    -- További tiltott járművek itt felsorolva
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
                    DeleteVehicle(vehicle)
                    break
                end
            end
        end
    end
end)
