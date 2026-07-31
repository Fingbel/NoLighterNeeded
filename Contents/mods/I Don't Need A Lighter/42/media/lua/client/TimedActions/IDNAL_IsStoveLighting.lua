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
	if instanceof(self.stove,'IsoStove') then
		if self.initialState == false then
			self.stove:Toggle() 
		end
	end
	--FinishTimeBasedAction
	ISBaseTimedAction.perform(self)
end

function IsStoveLighting:new (character, stove, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stove = stove
	o.item = item;
	o.maxTime = time;
	if instanceof(stove,'IsoStove') then
		o.initialState = stove:Activated()
	end
	if character:isTimedActionInstant() then
		o.maxTime = 1;
	end
	return o
end