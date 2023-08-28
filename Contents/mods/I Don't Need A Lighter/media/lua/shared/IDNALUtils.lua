--I Don't Need A Lighter Mod by Fingbel


-- if getCore():isDedicated()

if getActivatedMods():contains("Smoker") or getActivatedMods():contains("jiggasGreenfireMod") or getActivatedMods():contains("MoreSmokes") then 
	IDNAL="MODDEDIDNAL"
else IDNAL="IDNAL"
end

--This function is responsible to confirm the presence of cigarette in the player inventory 
--This function return an array(duplicate removed) of one of each of the possible smokable items

function IDNALCheckInventoryForCigarette(player)
	local inventoryItems = player:getInventory():getItems()
	local smokable = {}
	
	--Do we have smokable in our pocket
	for i=0, inventoryItems:size()-1 do			
		if inventoryItems:get(i):getEatType() ==  ('Cigarettes') or inventoryItems:get(i):getEatType() == ('CigarettesOne') then
			--if inventoryItems:get(i):getDisplayName() ~= ('Candy Cigarette') then
				smokable[IDNALgetTableSize(smokable)] = inventoryItems:get(i)
			--end
		end	
	end

	--Now we look for container to search inside
	for i=0, inventoryItems:size()-1 do	
		if inventoryItems:get(i):getCategory() == ("Container") then
		
			--We look inside each container for smokable
			local ContainerContent = inventoryItems:get(i):getItemContainer():getItems()				
			for i=0, ContainerContent:size()-1 do				
				if ContainerContent:get(i):getEatType() ==  ('Cigarettes') or ContainerContent:get(i):getEatType() == ('CigarettesOne')  then
					--if inventoryItems:get(i):getDisplayName() ~= ('Candy Cigarette') then
						smokable[IDNALgetTableSize(smokable)] = ContainerContent:get(i)
					--end
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
