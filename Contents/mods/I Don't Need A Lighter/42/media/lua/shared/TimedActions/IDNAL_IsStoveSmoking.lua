--NoLighterNeeded Mod by Fingbel

require "TimedActions/ISBaseTimedAction"

IsStoveSmoking = ISBaseTimedAction:derive('IsStoveSmoking')

function IsStoveSmoking:isValid()
	return self.character:getInventory():contains(self.item);
end

function IsStoveSmoking:update()

	--Make progress bar move
	self.item:setJobDelta(self:getJobDelta());
	
end

function IsStoveSmoking:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 460; -- 4.6 seconds (1s = 50 cycles)
end

function IsStoveSmoking:start()
	
	--This bypass the lighter durability drainage
	self.item:setRequireInHandOrInventory(nil)
	--Start Audio
	self.character:getEmitter():playSound("NoLighterSmoke");

	self:setAnimVariable("FoodType", self.item:getEatType());
	self.item:setJobDelta(0.0);

	self:setOverrideHandModels(nil, self.item);
	self:setActionAnim("Eat");
	
	--TODO : Add an option to allow the automatic turn off of self.stove after the animation started
	
	end

function IsStoveSmoking:stop()
     self.character:getEmitter():stopAll()
	
	--Reset Progress Bar
	self.item:setJobDelta(0.0);
	
	--StopTimeBasedAction
	ISBaseTimedAction.stop(self);
	
	end

function IsStoveSmoking:perform()
	
	--Reset Progress Bar
	self.item:setJobDelta(0.0);
	
	--FinishTimeBasedAction
	ISBaseTimedAction.perform(self)
	
end

function IsStoveSmoking:complete()
	--Consume the cigarette and apply its effects (server / single-player)
	self.character:Eat(self.item, 1)
	return true
end

function IsStoveSmoking:new (character, worldobject, item)
	local o = ISBaseTimedAction.new(self, character)
	o.stats = character:getStats();
	o.worldobject = worldobject;
	o.item = item;	
	o.maxTime = o:getDuration();
	o.eatAudio = 0
	 o.eatSound = item:getCustomEatSound() or "Eating";
	o.eatType = 'cigarette'
	o.stopOnWalk = false;
	o.stopOnRun = true;
	return o
end