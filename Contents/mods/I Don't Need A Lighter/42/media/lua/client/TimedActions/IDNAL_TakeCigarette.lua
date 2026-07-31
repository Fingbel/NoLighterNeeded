-- Timed action for taking one cigarette from a pack
-- In perform() it creates the cig, removes 1 use from pack, then chains the smoking pipeline

require "TimedActions/ISBaseTimedAction"
require "client/TimedActions/IDNAL_IsStoveLighting"
require "client/TimedActions/IDNAL_IsStoveSmoking"

IDNALTakeCigarette = ISBaseTimedAction:derive('IDNALTakeCigarette')

function IDNALTakeCigarette:isValid()
    return self.character and self.character:getInventory():contains(self.pack) and self.pack:getCurrentUses() > 0
end

function IDNALTakeCigarette:update()
    self.pack:setJobDelta(self:getJobDelta());
end

function IDNALTakeCigarette:start()
    self.pack:setJobDelta(0.0);
end

function IDNALTakeCigarette:stop()
    self.pack:setJobDelta(0.0);
    ISBaseTimedAction.stop(self)
end

function IDNALTakeCigarette:perform()
    self.pack:setJobDelta(0.0);
    
    -- Remove 1 use from the pack
    if self.pack:getCurrentUses() and self.pack:getCurrentUses() > 0 then
        self.pack:setCurrentUses(self.pack:getCurrentUses() - 1)
    end
    
    -- Mark this action as complete FIRST
    ISBaseTimedAction.perform(self)
    
    -- NOW spawn the cigarette (exists in inventory immediately)
    local singleCig = self.character:getInventory():AddItem("Base.CigaretteSingle")
    
    -- Queue the smoking pipeline (runs after this action is fully done)
    if singleCig then
        if self.useCar then
            OnCarSmoking(self.character, singleCig)
        elseif self.heatSource then
            IDNALOnStoveSmoking(self.character, self.heatSource, singleCig)
        end
    end
end

function IDNALTakeCigarette:new(character, heatSource, pack, time, useCar)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.heatSource = heatSource  -- Fixed: uppercase S to match self.heatSource
    o.useCar = useCar or false
    o.pack = pack
    o.maxTime = time or 15
    o.stopOnWalk = false
    o.stopOnRun = true
    return o
end
