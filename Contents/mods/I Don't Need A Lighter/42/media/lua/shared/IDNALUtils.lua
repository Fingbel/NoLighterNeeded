--I Don't Need A Lighter Mod by Fingbel
IDNAL_DEBUG = false
--This function return an array(duplicate removed) of one of each of the possible smokable items
--(loose cigarettes, pipes and the usable cigarette pack with the least uses left)
function IDNALCheckInventoryForCigarette(player)
	local inventoryItems = player:getInventory():getItems()
	local smokable = {}
	local bestPack = nil
	local bestPackUses = 0
	local bestPackID = 0
	
	--Among all usable packs, keep the one with the lowest uses left
	--(ties broken by lowest item ID so the selection stays stable)
	local function considerPack(item)
		local uses = item:getCurrentUses()
		if uses and uses > 0 then
			if not bestPack or uses < bestPackUses or (uses == bestPackUses and item:getID() < bestPackID) then
				bestPack = item
				bestPackUses = uses
				bestPackID = item:getID()
			end
		end
	end
	
	--Do we have smokable in our pocket
	for i=0, inventoryItems:size()-1 do				
		local item = inventoryItems:get(i)
		if item:getType() == "CigarettePack" then
			considerPack(item)
		elseif IDNALIsSmokable(item) then
			smokable[IDNALgetTableSize(smokable)] = item		
		end				
	end

	--Now we look for container to search inside
	for i=0, inventoryItems:size()-1 do	
		if inventoryItems:get(i):getCategory() == ("Container") then
		
			--We look inside each container for smokable
			local ContainerContent = inventoryItems:get(i):getItemContainer():getItems()				
			for i=0, ContainerContent:size()-1 do				
				local item = ContainerContent:get(i)
				if item:getType() == "CigarettePack" then
					considerPack(item)
				elseif IDNALIsSmokable(item) then
					smokable[IDNALgetTableSize(smokable)] = item
				end
			end
		end
	end
	if bestPack then
		smokable[IDNALgetTableSize(smokable)] = bestPack
	end
	if IDNALgetTableSize(smokable) == 0 then return nil end
	return IDNALremoveDuplicates(smokable)
end

-- Queue the pack pipeline (client-side only, uses ISTimedActionQueue):
-- move the pack to the main inventory (vanilla behavior), take one cigarette,
-- then put the pack back where it was.
function IDNALStartPackSmoking(player, pack, heatSource, useCar)
	if not ISTimedActionQueue then return end
	if not player or not pack then return end
	if pack:getType() ~= "CigarettePack" then return end
	if not (pack:getCurrentUses() and pack:getCurrentUses() > 0) then return end
	
	local mainInv = player:getInventory()
	local originalContainer = pack:getContainer()
	
	if originalContainer and originalContainer ~= mainInv then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(player, pack, originalContainer, mainInv, 5))
		ISTimedActionQueue.add(IDNALTakeCigarette:new(player, heatSource, pack, useCar))
		ISTimedActionQueue.add(ISInventoryTransferAction:new(player, pack, mainInv, originalContainer, 5))
	else
		ISTimedActionQueue.add(IDNALTakeCigarette:new(player, heatSource, pack, useCar))
	end
end



-- Checks if an item can be smoked (cigarettes, single cigarettes, pipes, etc.)
function IDNALIsSmokable(item)
	if not item then return false end
	local ok, eatType = pcall(function() return item:getEatType() end)
	if not ok then return false end
	return eatType == "Cigarettes" or eatType == "CigarettesOne" or eatType == "Pipe"
end


--Utility functions
function IDNALinArray(arr, element)
	for i=0,IDNALgetTableSize(arr) -1 do
		if arr[i]:getType() == element:getType()
			then return true 
		end
	end
	return false
end
	 
function IDNALremoveDuplicates(arr)
	local newArray = {}
	for i=0, IDNALgetTableSize(arr) -1 do

		if not IDNALinArray(newArray, arr[i]) then
			newArray[IDNALgetTableSize(newArray)] = arr[i]
		end
	end
	return newArray
end

function IDNALgetTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end
-- Détection du label localisé pour une heat source
function IDNALGetHeatSourceLabel(heatSource)
    if not heatSource then return nil end
    local sq = heatSource.getSquare and heatSource:getSquare() or nil
    if sq then
        for i=0, sq:getObjects():size()-1 do
            local obj = sq:getObjects():get(i)
            if obj.getSpriteName and obj:getSpriteName() == "camping_01_5" then
                return getText("IGUI_ContainerTitle_campfire")
            end
        end
        for i=0, sq:getObjects():size()-1 do
            local obj = sq:getObjects():get(i)
            if obj.getObjectName then
                local objName = obj:getObjectName()
                IDNALDebugPrint("Heat source object name: " .. tostring(objName))
                                if objName == "Barbecue" then
                    return getText("IGUI_ContainerTitle_barbecue")
                elseif objName == "Stove" then
                    if obj.isMicrowave and obj:isMicrowave() then
                        return getText("IGUI_ContainerTitle_microwave")
                    end
                    return getText("IGUI_ContainerTitle_stove")                
                elseif objName == "Fireplace" then
                    return getText("IGUI_ContainerTitle_woodstove")
                end
            end
        end
        if sq:haveFire() then
            return getText("IGUI_BurningTile") or "Burning Tile"
        end
    end
        if heatSource.getObjectName then
        local objName = heatSource:getObjectName()
        if objName == "Stove" then
            if heatSource.isMicrowave and heatSource:isMicrowave() then
                return getText("IGUI_ContainerTitle_microwave")
            end
            return getText("IGUI_ContainerTitle_woodstove")
        elseif objName == "Oven" then
            return getText("IGUI_ContainerTitle_stove")
        elseif objName and objName ~= "" then
            return objName
        end
    elseif heatSource.getName then
        return heatSource:getName()
    end
    return nil
end

function IDNALDebugPrint(message)
	if not IDNAL_DEBUG then return end
	print("[IDNAL DEBUG] " .. tostring(message))
end

-- Détection d'une source de chaleur valide (shared: loaded on client AND server)
-- Durations are in cycles (1s = 50 cycles) for use by getDuration()
function IDNALIsValidHeatSource(obj)
	if not obj then return {valid=false, priority=99} end
	-- B42-safe electricity check
	local powered = false
	local ok, modifier = pcall(function() return SandboxVars.ElecShutModifier end)
	if ok and modifier ~= nil then
		powered = modifier > -1 and getGameTime():getNightsSurvived() < modifier
	end
	if not powered and obj:getSquare() then
		powered = obj:getSquare():haveElectricity()
	end
	if obj:getObjectName() == "Stove" and not (instanceof(obj, 'IsoStove') and obj:isMicrowave()) and powered then
		return {valid=true, duration=150, priority=1} -- 1 second
	elseif obj:getObjectName() == "Fireplace" and obj:isLit() then
		return {valid=true, duration=150, priority=2}
	elseif obj:getObjectName() == "Barbecue" and obj:isLit() then
		return {valid=true, duration=150, priority=3}
	elseif obj:getObjectName() == "IsoObject" and obj:getSpriteName() == "camping_01_5" then
		return {valid=true, duration=170, priority=4}
	elseif obj:getSquare() and obj:getSquare():haveFire() then
		return {valid=true, duration=10 , priority=5}
	elseif instanceof(obj, 'IsoStove') and obj:isMicrowave() and powered then
		return {valid=true, duration=1500, priority=6} -- 30 seconds
	end
	return {valid=false, priority=99}
end
