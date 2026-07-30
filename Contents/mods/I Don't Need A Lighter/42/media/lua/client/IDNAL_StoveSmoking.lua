require 'client/TimedActions/IDNAL_IsStoveLighting'
require 'client/TimedActions/IDNAL_IsStoveSmoking'

local StoveSmoking = {}


-- Utilitaires refactorisés
function IDNALIsValidHeatSource(obj)
	if not obj then return {valid=false} end
	if obj:getObjectName() == "Stove" and ((SandboxVars.ElecShutModifier > -1 and getGameTime():getNightsSurvived() < SandboxVars.ElecShutModifier) or obj:getSquare():haveElectricity()) then
		return {valid=true, duration=100}
	elseif obj:getObjectName() == "Fireplace" and obj:isLit() then
		return {valid=true, duration=100}
	elseif obj:getObjectName() == "Barbecue" and obj:isLit() then
		return {valid=true, duration=100}
	elseif obj:getObjectName() == "IsoObject" and obj:getSpriteName() == "camping_01_5" then
		return {valid=true, duration=120}
	elseif obj:getSquare() and obj:getSquare():haveFire() then
		return {valid=true, duration=10}
	elseif instanceof(obj, 'IsoStove') and obj:isMicrowave() then
		return {valid=true, duration=3000}
	end
	return {valid=false}
end

local function removeSmokingMask(player)
	local wornItems = player:getWornItems()
	for i=0, wornItems:size()-1 do
		local itemLocation = wornItems:get(i):getLocation()
		if itemLocation == "MaskEyes" or itemLocation == "FullHat" or itemLocation == "Mask" then
			local item = wornItems:get(i):getItem()
			ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
			return item
		end
	end
	return nil
end

local function restoreSmokingMask(player, item)
	if item then
		ISTimedActionQueue.add(ISWearClothing:new(player, item, 50))
	end
end

local function startLightingAction(player, source, cigarette)
	local heat = IDNALIsValidHeatSource(source)
	if heat.valid then
		ISTimedActionQueue.add(IsStoveLighting:new(player, source, cigarette, heat.duration))
		return true
	end
	return false
end



--This function is responsible for the drawing of the context depending on the smokable array size
function ContextDrawing(player, context, stove, smokables)
	
	if stove == nil then return end
	
	--If we do not have nothing to smoke then we don't draw anything
	if smokables == nil then return

		--PREVIOUS METHOD : This add a red option not selectable, this create clutter
		--local foo = context:addOptionOnTop(getText('ContextMenu_Smoke'), player, stove)
		--foo.notAvailable = true
		--return	

		--If we have only one smokable type in the array 
	elseif IDNALgetTableSize(smokables) == 1 then
		option = context:addOptionOnTop(getText('ContextMenu_Smoke') .."  ".. smokables[0]:getDisplayName(), player, IDNALOnStoveSmoking, stove, smokables[0])
		if smokables[0].getTexture then
			option.iconTexture = smokables[0]:getTexture()
		end
	return
	end

		--We have more than on type, we need to draw a sub-menu
	local smokeOption = context:addOptionOnTop(getText('ContextMenu_Smoke'), stove, nil);	
	if smokables[0] and smokables[0].getTexture then
		smokeOption.iconTexture = smokables[0]:getTexture()
	end	
	local subMenu = ISContextMenu:getNew(context)
	for i=0,IDNALgetTableSize(smokables) -1 do	

		option = subMenu:addOptionOnTop(smokables[i]:getDisplayName(), player, IDNALOnStoveSmoking, stove, smokables[i])
		if smokables[i].getTexture then
			option.iconTexture = smokables[i]:getTexture()
		end
		context:addSubMenu(smokeOption, subMenu);		
	end
end

local function WhatIsUnderTheMouse(worldObjects, playerObj)
	for i, stove in ipairs(worldObjects) do
		--Détection d'un joueur en train de fumer
		for x = stove:getSquare():getX() - 1, stove:getSquare():getX() + 1 do
			for y = stove:getSquare():getY() - 1, stove:getSquare():getY() + 1 do
				local sq = getCell():getGridSquare(x, y, stove:getSquare():getZ())
				if sq then
					for j = 0, sq:getMovingObjects():size() - 1 do
						local o = sq:getMovingObjects():get(j)
						if instanceof(o, "IsoPlayer") and (o ~= playerObj) then
							if string.match(o:getAnimationDebug(), "foodtype : Cigarettes") then
								return o
							end
						end
					end
				end
			end
		end
		-- Utilisation de la fonction utilitaire
		if IDNALIsValidHeatSource(stove).valid then return stove end
	end
end

local function LightCigOnStove(_player, context, worldObjects, _test)
	if _test then return true end
	local player = getSpecificPlayer(_player)
	local smokables = IDNALCheckInventoryForCigarette(player)
	ContextDrawing(player, context, WhatIsUnderTheMouse(worldObjects, player), smokables)
end

Events.OnPreFillWorldObjectContextMenu.Add(LightCigOnStove)

function IDNALOnStoveSmoking(_player, stove, _cigarette)
	-- Rendre la fonction accessible globalement (pour _G.OnStoveSmoking)
	ISWorldObjectContextMenu.Test = true
	-- Vérification joueur
	if instanceof(stove, 'IsoPlayer') then
		if not string.match(stove:getAnimationDebug(), "foodtype : Cigarettes") then return end
	end
	-- Transfert cigarette si besoin
	if luautils.walkAdj(_player, stove:getSquare(), true) then
		if _cigarette:getContainer() ~= _player:getInventory() then
			ISTimedActionQueue.add(ISInventoryTransferAction:new(_player, _cigarette, _cigarette:getContainer(), _player:getInventory(), 5))
		end
	end
	-- Gestion du masque
	local removedMask = removeSmokingMask(_player)
	-- Allumage
	if luautils.walkAdj(_player, stove:getSquare(), true) then
		startLightingAction(_player, stove, _cigarette)
	end
	-- Fumer
	if luautils.walkAdj(_player, stove:getSquare(), true) then
		ISTimedActionQueue.add(IsStoveSmoking:new(_player, stove, _cigarette, 460))
	end
	-- Remettre le masque
	restoreSmokingMask(_player, removedMask)
end