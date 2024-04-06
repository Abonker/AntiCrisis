RegisterServerEvent("kickPlayer")
AddEventHandler("kickPlayer", function()
    local src = source
    DropPlayer(src, "Tiltott jármű használata!")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Ebben az esetben minden másodpercben ellenőrizzük a játékosok pozícióját.

        -- Itt megadhatod a Z koordinátát, amely felett a játékosokat kickelni szeretnéd.
        local kickHeight = 300

        -- Iterálunk minden játékoson a szerveren
        for _, playerId in ipairs(GetPlayers()) do
            -- Lekérjük a játékos pozícióját
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)

            -- Ellenőrizzük, hogy a játékos magassága meghaladja-e a kick magasságát
            if playerCoords.z > kickHeight then
                -- Ha igen, kickeljük a játékost
                DropPlayer(playerId, "Elhagytad a megengedett területet.")
            end
        end
    end
end)

-- Speedhack ellenőrzés
local function SpeedhackCheck(playerPed)
    local playerSpeed = GetEntitySpeed(playerPed)
    if playerSpeed > 200 then -- Például ha a játékos sebessége 200 egység/másodperc felett van
        return true
    end
    return false
end

-- Damage boost észlelése
local function DamageBoostCheck(playerPed)
    local weaponHash = GetSelectedPedWeapon(playerPed)
    local damageBoostWeapons = {
        "WEAPON_APPISTOL"
    }
    for _, boostWeaponHash in ipairs(damageBoostWeapons) do
        if weaponHash == GetHashKey(boostWeaponHash) then
            return true
        end
    end
    return false
end

-- Teleport észlelése
local function TeleportCheck(playerPed, lastCoords)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - lastCoords)
    if distance > 50 then -- Például ha a játékos hirtelen több mint 50 egységet mozog
        return true
    end
    return false
end

-- Wallhack ellenőrzés
local function WallhackCheck(playerPed, targetPed)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local rayHandle = StartShapeTestRay(playerCoords, targetCoords, 1, playerPed, 7)
    local _, _, _, _, result = GetShapeTestResult(rayHandle)
    if result then
        return true
    end
    return false
end

-- God mode észlelése
local function GodModeCheck(playerPed)
    local playerHealth = GetEntityHealth(playerPed)
    if playerHealth > 200 then -- Például ha a játékos életereje 200-nál nagyobb
        return true
    end
    return false
end

-- Érvénytelen események szűrése
local function InvalidEventCheck()
    local eventType = GetEventType()
    if eventType == "illegal_event" then
        return true
    end
    return false
end

Citizen.CreateThread(function()
    local lastPlayerCoords = {}
    while true do
        Citizen.Wait(1000) -- Ellenőrzés másodpercenként

        for _, playerId in ipairs(GetPlayers()) do
            local playerPed = GetPlayerPed(playerId)
            local playerId = GetPlayerServerId(playerId)

            if SpeedhackCheck(playerPed) then
                DropPlayer(playerId, "Speedhack észlelve")
            elseif DamageBoostCheck(playerPed) then
                DropPlayer(playerId, "Damage boost észlelve")
            elseif TeleportCheck(playerPed, lastPlayerCoords[playerId] or GetEntityCoords(playerPed)) then
                DropPlayer(playerId, "Teleport észlelve")
            elseif GodModeCheck(playerPed) then
                DropPlayer(playerId, "God mode észlelve")
            elseif InvalidEventCheck() then
                DropPlayer(playerId, "Érvénytelen esemény észlelve")
            end

            lastPlayerCoords[playerId] = GetEntityCoords(playerPed)
        end
    end
end)
