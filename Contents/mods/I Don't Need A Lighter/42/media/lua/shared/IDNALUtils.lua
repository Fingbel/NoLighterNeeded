--I Don't Need A Lighter Mod by Fingbel
IDNAL_DEBUG = false
--This function return an array(duplicate removed) of one of each of the possible smokable items
function IDNALCheckInventoryForCigarette(player)
	local inventoryItems = player:getInventory():getItems()
	local smokable = {}
	
	--Do we have smokable in our pocket
	for i=0, inventoryItems:size()-1 do				

		if inventoryItems:get(i):getEatType() ==  ('Cigarettes') or inventoryItems:get(i):getEatType() == ('CigarettesOne') then			
			if inventoryItems:get(i):getType() ~= "CigarettePack" then --We don't want packs in the list
				smokable[IDNALgetTableSize(smokable)] = inventoryItems:get(i)		
			end
					
		end	
	end

	--Now we look for container to search inside
	for i=0, inventoryItems:size()-1 do	
		if inventoryItems:get(i):getCategory() == ("Container") then
		
			--We look inside each container for smokable
			local ContainerContent = inventoryItems:get(i):getItemContainer():getItems()				
			for i=0, ContainerContent:size()-1 do				
				if ContainerContent:get(i):getEatType() ==  ('Cigarettes') or ContainerContent:get(i):getEatType() == ('CigarettesOne')  then									
					if ContainerContent:get(i):getType() ~= "CigarettePack" then --We don't want packs in the list
						smokable[IDNALgetTableSize(smokable)] = ContainerContent:get(i)		
					end
				end
			end
		end
	end
	if IDNALgetTableSize(smokable) == 0 then return nil end
	return IDNALremoveDuplicates(smokable)
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
