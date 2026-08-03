--NoLighterNeeded Mod by Fingbel

require "TimedActions/ISBaseTimedAction"


IsCarLighting = ISBaseTimedAction:derive('IsCarLighting')

function IsCarLighting:isValid()
	return self.character:getInventory():contains(self.item);
end

function IsCarLighting:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 300; -- 3 seconds (1s = 50 cycles)
end

function IsCarLighting:start()
	--This bypass the lighter durability drainage
	self.item:setRequireInHandOrInventory(nil)
	
	--Start Audio
	self.character:getEmitter():playSound("CarLighter_PlugIn");
end

function IsCarLighting:stop()
	
	--Start audio
	self.character:getEmitter():playSound("CarLighter_PlugOut");

	--StopTimeBasedAction
	ISBaseTimedAction.stop(self);	
end

function IsCarLighting:perform()
	
	self.character:getEmitter():playSound("CarLighter_PlugOut");
	battery = self.character:getVehicle():getBattery():getInventoryItem()
	--battery:setUsedDelta(battery:getUsedDelta() -0.02)   BROKE BY B42 UPDATE

	--FinishTimeBasedAction
	ISBaseTimedAction.perform(self)
end

function IsCarLighting:complete()
	--Battery drain is disabled (B42 API changed)
	return true
end

function IsCarLighting:new (character, item)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item;
	o.maxTime = o:getDuration();
	return o
end


