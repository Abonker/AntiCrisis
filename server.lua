RegisterServerEvent("kickPlayer")
AddEventHandler("kickPlayer", function()
    local src = source
    DropPlayer(src, "Tiltott jarmu hasznalata!")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Ebben az esetben minden masodpercben ellenorizzük a jatekosok pozíciójat.

        -- Itt megadhatod a Z koordinatat, amely felett a jatekosokat kickelni szeretned.
        local kickHeight = 400

        -- Iteralunk minden jatekoson a szerveren
        for _, playerId in ipairs(GetPlayers()) do
            -- Lekerjük a jatekos pozíciójat
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)

            -- Ellenorizzük, hogy a jatekos magassaga meghaladja-e a kick magassagat
            if playerCoords.z > kickHeight then
                -- Ha igen, kickeljük a jatekost
                DropPlayer(playerId, "Elhagytad a megengedett területet.")
            end
        end
    end
end)

-- Speedhack ellenorzes
local function SpeedhackCheck(playerPed)
    local playerSpeed = GetEntitySpeed(playerPed)
    if playerSpeed > 200 then -- Peldaul ha a jatekos sebessege 200 egyseg/masodperc felett van
        return true
    end
    return false
end

-- Damage boost eszlelese
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

-- Teleport eszlelese
local function TeleportCheck(playerPed, lastCoords)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - lastCoords)
    if distance > 50 then -- Peldaul ha a jatekos hirtelen tobb mint 50 egyseget mozog
        return true
    end
    return false
end

-- Wallhack ellenorzes
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

-- God mode eszlelese
local function GodModeCheck(playerPed)
    local playerHealth = GetEntityHealth(playerPed)
    if playerHealth > 200 then -- Peldaul ha a jatekos eletereje 200-nal nagyobb
        return true
    end
    return false
end

-- ervenytelen esemenyek szurese
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
            elseif IsDropPlayerTriggered() then
                TriggerServerEvent('banPlayer', playerId)
            end

            lastPlayerCoords[playerId] = GetEntityCoords(playerPed)
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)
        
        -- Az NPC-k spawnolasanak megakadalyozasa
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        
        -- NPC-k azonnali torlese
        local pedList = GetGamePool('CPed')
        for i = 1, #pedList do
            if pedList[i] ~= ped then
                DeleteEntity(pedList[i])
            end
        end
    end
end)

local bannedPlayers = {}

-- Betölti a bannolt játékosokat a JSON fájlból
local function loadBannedPlayers()
    local file = LoadResourceFile(GetCurrentResourceName(), 'banlist.json')
    if file then
        bannedPlayers = json.decode(file)
    end
end

-- Ment egy bannolt játékost a JSON fájlba
local function saveBannedPlayers()
    SaveResourceFile(GetCurrentResourceName(), 'banlist.json', json.encode(bannedPlayers, { indent = true }), -1)
end

-- Felismeri a játékos ID-jét és bannolja, ha nincs benne a listán
RegisterServerEvent('banPlayer')
AddEventHandler('banPlayer', function()
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]
    DropPlayer(src, "Ki lettél tiltva szerveről az AntiCheat Által!")
    
    if not bannedPlayers[identifier] then
        bannedPlayers[identifier] = true
        saveBannedPlayers()
    end
end)

-- Ellenőrzi a bejelentkező játékosokat
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifiers(src)[1]

    if bannedPlayers[identifier] then
        deferrals.defer()
        deferrals.update('Nem léphetsz be a szerverre, mert bannolva vagy.')
        Wait(2000)
        deferrals.done('Kicked')
    else
        deferrals.done()
    end
end)

-- Betölti a bannolt játékosokat induláskor
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadBannedPlayers()
    end
end)
