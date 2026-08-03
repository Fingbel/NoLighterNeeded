--NoLighterNeeded Mod by Fingbel

require "TimedActions/ISBaseTimedAction"


IsStoveLighting = ISBaseTimedAction:derive('IsStoveLighting')

function IsStoveLighting:isValid()
	return self.character:getInventory():contains(self.item);
end


function IsStoveLighting:waitToStart()
	--Face the correct direction
	self.character:faceThisObject(self.stove)
	return self.character:shouldBeTurning()
end

function IsStoveLighting:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	if IDNALIsValidHeatSource then
		local heat = IDNALIsValidHeatSource(self.stove)
		if heat and heat.valid then
			return heat.duration
		end
	end
	return 50;
end

function IsStoveLighting:start()
	self:setActionAnim("Craft");
	--This bypass the lighter durability drainage
	
	self.item:setRequireInHandOrInventory(nil)
	if instanceof(self.stove,'IsoStove') then
		if self.initialState == false then
			self.stove:Toggle()
			if self.stove:isMicrowave() then
				self.stove:setTimer(2000) -- Keep it on for 10 seconds to outlast our lighting action
			end
		end
	end
end



function IsStoveLighting:stop()
	--StopTimeBasedAction
	if instanceof(self.stove,'IsoStove') then
		if self.initialState == false then
			self.stove:Toggle()
		end
	end
	ISBaseTimedAction.stop(self);	
end


function IsStoveLighting:perform()
	--FinishTimeBasedAction
	if instanceof(self.stove,'IsoStove') then
		if self.initialState == false then
			self.stove:Toggle()
		end
	end
	ISBaseTimedAction.perform(self)
end

function IsStoveLighting:complete()
	--Restore the stove to its initial state (server / single-player)	
	return true
end

function IsStoveLighting:new (character, stove, item)
	local o = ISBaseTimedAction.new(self, character)
	o.stove = stove
	o.item = item;
	if instanceof(stove,'IsoStove') then
		o.initialState = stove:Activated()
	end
	o.maxTime = o:getDuration();
	return o
end