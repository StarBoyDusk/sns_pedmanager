PedManager = {}
local PedManager = {}
PedManager.registered = {}
PedManager.npcPoints = {}
PedManager.defaultSpawnDistance = 100
PedManager.defaultDespawnDistance = 150
local registeredInteractions = {}
PedManager.Blips = {}
PedManager.npcBlips = {}

local function GetHashFromString(value)
    if type(value) == "string" then
        local number = tonumber(value)
        if number then return number end
        return joaat(value)
    end
    return value
end

local function createBlip(location, name, sprite, blipHash, color)
    if not blipHash then blipHash = 1664425300 end
    if type(sprite) == "string" then sprite = joaat(sprite) end
    local blip = BlipAddForCoords(blipHash, location.x, location.y, location.z)
    SetBlipSprite(blip, sprite)
    SetBlipName(blip, name)
    if color then
        BlipAddModifier(blip, GetHashFromString(color))
    end
    PedManager.Blips[#PedManager.Blips + 1] = blip
    return blip
end

local function applyPedOutfit(ped, npcData)
    if not DoesEntityExist(ped) then return false end
    npcData = npcData or {}

    local outfitPreset = npcData.outfit

    if outfitPreset ~= nil then
        local presetId = tonumber(outfitPreset)
        if presetId then
            SetPedOutfitPreset(ped, presetId)
            return true
        else
            Print("^3[SNS PedManager] Invalid outfit preset for NPC: " .. tostring(npcData.id) .. "^0")
        end
    else
        SetRandomOutfitVariation(ped, true)
        return true
    end

    return false
end

-- ox_lib Points für NPC-Spawn
function PedManager:createNPCPoint(npcData)
    if not lib or not lib.points then
        error("^1ox_lib points module is required for PedManager!^0", 2)
    end

    local point = lib.points.new({
        coords = vector3(npcData.x, npcData.y, npcData.z),
        distance = npcData.spawnDistance or self.defaultSpawnDistance,
        onEnter = function()
            self:spawnPed(npcData)
        end,
        onExit = function()
            self:removePed(npcData)
        end,
        nearby = function()
            if npcData.onNearby then
                npcData.onNearby(npcData)
            end
        end
    })

    self.npcPoints[npcData.id or #self.npcPoints + 1] = point
    return point
end

function PedManager.RemoveInteraction(entityId)
    local uniqueId = "interaction_" .. tostring(entityId)
    if not registeredInteractions[uniqueId] then return end
    exports.murphy_interact:RemoveInteraction(uniqueId)
    registeredInteractions[uniqueId] = false
end

function PedManager.AddInteraction(interactionData, entityId)
    local inD = interactionData
    local uniqueId = "interaction_" .. tostring(entityId)

    local coords = GetEntityCoords(entityId)

    exports.murphy_interact:AddInteraction({
        coords = vec3(coords.x, coords.y, coords.z),
        id = uniqueId,
        distance = inD.distance or 5,
        interactDst = inD.interactDst or 5,
        ignoreLos = inD.ignoreLos,
        offset = inD.offset or vec3(0.0, 0.0, 0.0),
        bone = inD.bone,
        title = inD.title,
        groups = inD.groups,
        options = interactionData.options or {}
    })

    registeredInteractions[uniqueId] = true
end

function PedManager.playScenario(ped, scenario)
    if not DoesEntityExist(ped) or not scenario then
        return
    end

    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

function PedManager.playAnimation(ped, animDict, animName)
    if not DoesEntityExist(ped) or not animDict or not animName then
        return
    end

    RequestAnimDict(animDict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
        if GetGameTimer() > timeout then
            Print("^1[SNS PedManager] Timeout beim Laden des Dicts '" .. animDict .. "'^0")
            return false
        end
    end
    TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, -1, 1, 0, false, false, false)
    return true
end

function PedManager:spawnPed(npcData)
    if npcData.ped then return end

    local x, y, z = tonumber(npcData.x), tonumber(npcData.y), tonumber(npcData.z - 1)
    local model = npcData.model
    local heading = tonumber(npcData.heading) or 0.0

    local hashModel = GetHashKey(model)
    if not IsModelValid(hashModel) then
        Print("^1[SNS PedManager] Invalid model: " .. model .. "^0")
        return
    end

    RequestModel(hashModel)
    while not HasModelLoaded(hashModel) do
        Wait(100)
    end

    local ped = CreatePed(hashModel, x, y, z, heading, false, true, true)
    applyPedOutfit(ped, npcData)
    Wait(200)

    SetEntityCollision(ped, true, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    self.playAnimation(ped, npcData.animDict, npcData.animName)
    self.playScenario(ped, npcData.scenario)

    local interactiondata = npcData.interaction

    if interactiondata and type(interactiondata) == "table" then
        self.AddInteraction(interactiondata, ped)
    end

    npcData.ped = ped

    if npcData.onSpawn then
        npcData.onSpawn(ped, npcData)
    end
end

function PedManager:removePed(npcData)
    if not npcData.ped then return end

    local ped = npcData.ped
    self.RemoveInteraction(ped)

    if DoesEntityExist(ped) then
        DeleteEntity(ped)
        DeletePed(ped)
        SetEntityAsNoLongerNeeded(ped)
    end

    npcData.ped = nil

    if npcData.onDespawn then
        npcData.onDespawn(npcData)
    end
end

function PedManager:register(resourceName, npcList, options)
    if type(resourceName) ~= 'string' or type(npcList) ~= 'table' then
        Print("^1[SNS PedManager] Invalid parameters for PedManager:register^0")
        return
    end

    options = options or {}

    local points = {}
    local blips = {}

    for i, npcData in ipairs(npcList) do
        npcData.spawnDistance = npcData.spawnDistance or options.spawnDistance or self.defaultSpawnDistance
        npcData.id = npcData.id or (resourceName .. "_" .. i)

        if npcData.outfit == nil and options.defaultOutfit ~= nil then
            npcData.outfit = options.defaultOutfit
        end

        local point = self:createNPCPoint(npcData)
        points[#points + 1] = point

        if npcData.blip and type(npcData.blip) == "table" then
            local location = vector3(npcData.x, npcData.y, npcData.z)
            local name = npcData.blip.name or npcData.id
            local sprite = npcData.blip.sprite
            local blipHash = npcData.blip.blipHash
            local color = npcData.blip.color

            if sprite then
                local blipId = createBlip(location, name, sprite, blipHash, color)
                if blipId then
                    blips[#blips + 1] = blipId
                end
            else
                Print("^3[SNS PedManager] Blip data found but missing sprite for NPC: " .. npcData.id .. "^0")
            end
        end
    end

    self.registered[resourceName] = {
        list = npcList,
        options = options,
        points = points
    }

    self.npcBlips[resourceName] = blips

    Print("^2[SNS PedManager] Registered " .. #npcList .. " NPCs for resource: " .. resourceName .. "^0")
    if #blips > 0 then
        Print("^2[SNS PedManager] Created " .. #blips .. " Blips for resource: " .. resourceName .. "^0")
    end
end

function PedManager:unregister(resourceName)
    local set = self.registered[resourceName]
    if not set then return end

    for _, point in pairs(set.points) do
        point:remove()
    end

    for _, npcData in pairs(set.list) do
        if npcData.ped then
            self:removePed(npcData)
        end
    end

    if self.npcBlips[resourceName] then
        for _, blipId in ipairs(self.npcBlips[resourceName]) do
            RemoveBlip(blipId)
        end
        self.npcBlips[resourceName] = nil
    end

    self.registered[resourceName] = nil
    Print("^2[SNS PedManager] Unregistered NPCs for resource: " .. resourceName .. "^0")
end

function PedManager:createMultipleNPCs(npcList)
    local points = {}
    for _, npcData in ipairs(npcList) do
        local point = self:createNPCPoint(npcData)
        points[#points + 1] = point
    end
    return points
end

function PedManager:removeNPCPoint(pointId)
    local point = self.npcPoints[pointId]
    if point then
        point:remove()
        self.npcPoints[pointId] = nil
    end
end

function PedManager:cleanupAll()
    for resourceName, _ in pairs(self.registered) do
        self:unregister(resourceName)
    end

    for i = #self.Blips, 1, -1 do
        local blip = self.Blips[i]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        table.remove(self.Blips, i)
    end
    self.Blips = {}
    self.npcBlips = {}

    for _, point in pairs(self.npcPoints) do
        point:remove()
    end

    self.registered = {}
    self.npcPoints = {}
end

function PedManager:getStats()
    local totalNPCs = 0
    local totalPoints = 0

    for _, set in pairs(self.registered) do
        totalNPCs = totalNPCs + #set.list
        totalPoints = totalPoints + #set.points
    end

    return {
        registeredResources = #self.registered,
        totalNPCs = totalNPCs,
        totalPoints = totalPoints,
        activePoints = #self.npcPoints
    }
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        PedManager:cleanupAll()
        return
    end

    if PedManager.registered[resource] then
        PedManager:unregister(resource)
    end
end)

AddEventHandler('sns_pedmanager:registerNpcs', function(resourceName, npcList, options)
    PedManager:register(resourceName, npcList, options)
end)

AddEventHandler('sns_pedmanager:unregisterNpcs', function(resourceName)
    PedManager:unregister(resourceName)
end)

exports('registerNpcs', function(resourceName, npcList, options)
    PedManager:register(resourceName, npcList, options)
end)

exports('unregisterNpcs', function(resourceName)
    PedManager:unregister(resourceName)
end)
