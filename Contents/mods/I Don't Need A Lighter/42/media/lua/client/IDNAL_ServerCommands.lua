--I Don't Need A Lighter Mod by Fingbel
-- Handles server -> client commands (Events.OnServerCommand)
-- The server creates/syncs the cigarette in IDNALTakeCigarette:complete() and
-- then sends "StartSmokingSequence" so the client can queue the smoke chain

local function FindCigaretteInContainer(container, cigID)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if cigID ~= nil and item:getID() == cigID then
                return item
            end
            if item:getType() == "CigaretteSingle" then
                return item -- fallback if ID lookup fails
            end
            if item:getCategory() == "Container" and item:getItemContainer() then
                local found = FindCigaretteInContainer(item:getItemContainer(), cigID)
                if found then return found end
            end
        end
    end
    return nil
end

local function TryStartSmokingSequence(player, args)
    local singleCig = FindCigaretteInContainer(player:getInventory(), args.cigID)
    if not singleCig then return false end

    if args.useCar then
        OnCarSmoking(player, singleCig)
    elseif args.heatSource then
        local sq = getCell():getGridSquare(args.heatSource.x, args.heatSource.y, args.heatSource.z)
        if sq then
            local heatSource = nil
            for i = 0, sq:getObjects():size() - 1 do
                local obj = sq:getObjects():get(i)
                if obj and obj:getObjectName() == args.heatSource.objectName then
                    local heat = IDNALIsValidHeatSource(obj)
                    if heat.valid then
                        heatSource = obj
                        break
                    end
                end
            end
            if heatSource then
                IDNALOnStoveSmoking(player, heatSource, singleCig)
            end
        end
    end
    return true
end

local function OnServerCommand(module, command, args)
    if module ~= "IDNAL" or command ~= "StartSmokingSequence" then return end
    if not args or not args.onlineID then return end

    local player = getPlayerByOnlineID(args.onlineID)
    if not player then player = getSpecificPlayer(0) end
    if not player then return end

    if not TryStartSmokingSequence(player, args) then
        local retries = 0
        local maxRetries = 300 -- up to ~5s
        local function retry()
            if TryStartSmokingSequence(player, args) then
                Events.OnTick.Remove(retry)
                return
            end
            retries = retries + 1
            if retries >= maxRetries then
                Events.OnTick.Remove(retry)
                IDNALDebugPrint("Could not find spawned cigarette after retries")
            end
        end
        Events.OnTick.Add(retry)
    end
end
Events.OnServerCommand.Add(OnServerCommand)
