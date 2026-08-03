--NoLighterNeeded Mod by Fingbel

local old_ISVehicleMenu_showRadialMenu = ISVehicleMenu.showRadialMenu

--This is the added code to the base function
function ISVehicleMenu.showRadialMenu(player)
	--Here we first call the base function
	old_ISVehicleMenu_showRadialMenu(player)	

	--Now we run some custom code
	local vehicle = player:getVehicle()
	local smokables = IDNALCheckInventoryForCigarette(player)

	if vehicle ~= nil then
		local menu = getPlayerRadialMenu(player:getPlayerNum())
		
		--Gamepad stuff
		if menu:isReallyVisible() then
			if menu.joyfocus then
				setJoypadFocus(player:getplayerObjNum(), nil)
			end 
			menu:undisplay()
			return
		end
		local seat = vehicle:getSeat(player)
		
		if seat == 0 or seat == 1 then
			
			--Do we have everything ?
			if smokables ~= nil and vehicle:getBatteryCharge() > 0 and (vehicle:isHotwired() or vehicle:isKeysInIgnition()) then
				if 	#smokables >= 1 then menu:addSlice(getText('ContextMenu_CarLighter'), getTexture("media/ui/vehicles/carSmokingBatteryCigarette.png"), IDNALOnSubMenu, player)				
					else menu:addSlice(getText('ContextMenu_CarLighter'),getTexture("media/ui/vehicles/carSmokingBatteryCigarette.png"), OnCarSmoking, player, smokables[0] ) 
				end
			
			--Missing cigs 
			elseif smokables == nil and vehicle:getBatteryCharge() > 0 and (vehicle:isHotwired() or vehicle:isKeysInIgnition()) then
				 menu:addSlice(getText('ContextMenu_CarLighter')  ..":" .. getText('ContextMenu_CarOutOfCigarette'), getTexture("media/ui/vehicles/carSmokingBatteryContactNoCigarette.png"))	
			
			--Missing cigs and battery 
			elseif smokables == nil and vehicle:getBatteryCharge() == 0 and (vehicle:isHotwired() or vehicle:isKeysInIgnition()) then
				menu:addSlice(getText('ContextMenu_CarLighter') ..":" .. getText('ContextMenu_CarOutOfCigarette') .. getText('ContextMenu_CarNoBattery'),getTexture("media/ui/vehicles/carSmokingNoBatteryContactNoCigarette.png")) 						
				
			--Missing cigs and battery and keys
			elseif smokables == nil and vehicle:getBatteryCharge() == 0 and (not vehicle:isHotwired() or not vehicle:isKeysInIgnition()) then
				menu:addSlice(getText('ContextMenu_CarLighter') ..":" .. getText('ContextMenu_CarOutOfCigarette') .. getText('ContextMenu_CarNoBattery') .. getText('ContextMenu_CarNoKeyOrWire'),getTexture("media/ui/vehicles/carSmokingNoBatteryNoContactNoCigarette.png") )

			--Missing cigs and keys
			elseif smokables == nil and vehicle:getBatteryCharge() > 0 and (not vehicle:isHotwired() or not vehicle:isKeysInIgnition()) then
				menu:addSlice(getText('ContextMenu_CarLighter') ..":".. getText('ContextMenu_CarOutOfCigarette') .. getText('ContextMenu_CarNoKeyOrWire'),getTexture("media/ui/vehicles/carSmokingBatteryNoContactNoCigarette.png") ) 
			
			--Missing keys
			elseif smokables ~= nil and vehicle:getBatteryCharge() > 0 and (not vehicle:isHotwired() or not vehicle:isKeysInIgnition()) then
				menu:addSlice(getText('ContextMenu_CarLighter') ..":" .. getText('ContextMenu_CarNoKeyOrWire'),getTexture("media/ui/vehicles/carSmokingBatteryNoContactCigarette.png")) 
			--Missing charge
			elseif smokables ~= nil and vehicle:getBatteryCharge() == 0 and  (vehicle:isHotwired() or  vehicle:isKeysInIgnition()) then
				 menu:addSlice(getText('ContextMenu_CarLighter') ..":".. getText('ContextMenu_CarNoBattery'),getTexture("media/ui/vehicles/carSmokingNoBatteryContactCigarette.png")) 
			
			--Missing charge and keys
			elseif smokables ~= nil and vehicle:getBatteryCharge() == 0 and (not vehicle:isHotwired() or not vehicle:isKeysInIgnition()) then
				 menu:addSlice(getText('ContextMenu_CarLighter') ..":".. getText('ContextMenu_CarNoBattery') .. getText('ContextMenu_CarNoKeyOrWire'),getTexture("media/ui/vehicles/carSmokingNoBatteryNoContactCigarette.png")) 
			end
		end
		menu:addToUIManager()
	end
end

--This is the function for the Sub-Menu for the modded version of the car lighter to show-up smokable while in a car
function IDNALOnSubMenu(player)
	local smokables = IDNALCheckInventoryForCigarette(player)
	local menu = getPlayerRadialMenu(player:getPlayerNum())
	menu:clear()
	
	--Draw the radial menu again
	menu:setX(getPlayerScreenLeft(player:getPlayerNum()) + getPlayerScreenWidth(player:getPlayerNum()) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(player:getPlayerNum()) + getPlayerScreenHeight(player:getPlayerNum()) / 2 - menu:getHeight() / 2)

	local texture = Joypad.Texture.AButton

	
	for i=0, IDNALgetTableSize(smokables) -1 do --TODO : this need to have a hardcap to not fuck up the radialmenu
		menu:addSlice(smokables[i]:getDisplayName(), smokables[i]:getTexture(), OnCarSmoking, player, smokables[i] )
	end
	
	menu:addToUIManager()

	if JoypadState.players[player:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(player:getPlayerNum(), menu)
		player:setJoypadIgnoreAimUntilCentered(true)
	end
end

--This is the function starting the car smoking sequence
function OnCarSmoking(_player, _cigarette)
	
	--Do we need to transfer cigarette from a bag first ? 
	if _cigarette:getContainer() ~= _player:getInventory() then
		ISTimedActionQueue.add(ISInventoryTransferAction:new (_player,  _cigarette, _cigarette:getContainer(), _player:getInventory(), 5))
	end

		--We need some time for the lighter to heat
	ISTimedActionQueue.add(IsCarLighting:new (_player, _cigarette))
	
	--Let's smoke now
	ISTimedActionQueue.add(IsCarSmoking:new(_player, _cigarette))
end