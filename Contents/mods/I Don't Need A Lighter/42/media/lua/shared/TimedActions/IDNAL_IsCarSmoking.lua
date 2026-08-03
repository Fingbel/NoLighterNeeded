--NoLighterNeeded Mod by Fingbel

require "TimedActions/ISBaseTimedAction"

IsCarSmoking = ISBaseTimedAction:derive('IsCarSmoking')

function IsCarSmoking:isValid()
	return self.character:getInventory():contains(self.item);
end

function IsCarSmoking:update()

	--Make progress bar move
	self.item:setJobDelta(self:getJobDelta());
	
     if self.eatAudio ~= 0 and not self.character:getEmitter():isPlaying(self.eatAudio) then
         self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
     end
end

function IsCarSmoking:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 460; -- 4.6 seconds (1s = 50 cycles)
end

function IsCarSmoking:start()
	--This bypass the lighter durability drainage
	self.item:setRequireInHandOrInventory(nil)
	
	--Start Audio
	if self.eatSound ~= '' then
         self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
	end
	self.item:setJobDelta(0.0);
	
	--Animation (client side; Eat() now only runs in complete() on the server)
	self:setAnimVariable("FoodType", self.item:getEatType());
	self:setOverrideHandModels(nil, self.item);
	self:setActionAnim("Eat");
	end

function IsCarSmoking:stop()
    --Stop Audio
   		if self.eatAudio ~= 0 and self.character:getEmitter():isPlaying(self.eatAudio) then
		self.character:stopOrTriggerSound(self.eatAudio);
	end
	
	--Reset Progress Bar
	self.item:setJobDelta(0.0);
	
	--StopTimeBasedAction
	ISBaseTimedAction.stop(self);
	
	end

function IsCarSmoking:perform()
	--Stop Audio
	if self.eatAudio ~= 0 and self.character:getEmitter():isPlaying(self.eatAudio) then
        self.character:stopOrTriggerSound(self.eatAudio);
    end
	
		--Reset Progress Bar
	self.item:setJobDelta(0.0);

	--FinishTimeBasedAction
	ISBaseTimedAction.perform(self)
end

function IsCarSmoking:complete()
	--Consume the cigarette and apply its effects (server / single-player)
	self.character:Eat(self.item, 1)
	return true
end

function IsCarSmoking:new (character, item)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item;
	o.maxTime = o:getDuration();
	o.eatSound ="Smoke";
	o.eatAudio = 0;
	return o
end