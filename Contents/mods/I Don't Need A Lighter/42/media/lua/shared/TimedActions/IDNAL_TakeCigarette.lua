require "TimedActions/ISBaseTimedAction"
require "TimedActions/IDNAL_IsCarLighting"
require "TimedActions/IDNAL_IsCarSmoking"
require "TimedActions/IDNAL_IsStoveLighting"
require "TimedActions/IDNAL_IsStoveSmoking"

IDNALTakeCigarette = ISBaseTimedAction:derive('IDNALTakeCigarette')

function IDNALTakeCigarette:isValid()
    return self.character and self.character:getInventory():contains(self.pack) and self.pack:getCurrentUses() > 0
end

function IDNALTakeCigarette:update()
    self.pack:setJobDelta(self:getJobDelta());
end

function IDNALTakeCigarette:getDuration()
    if self.character:isTimedActionInstant() then
        return 1;
    end
    return 50; -- 1 second (1s = 50 cycles)
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
    --FinishTimeBasedAction (client side: visuals only; item work is done in complete())
    ISBaseTimedAction.perform(self)
end

function IDNALTakeCigarette:complete()
    -- Server-authoritative item manipulation (see B42 doc, section 5).
    -- 1) Decrement the pack and sync it to clients.
    if self.pack:getCurrentUses() and self.pack:getCurrentUses() > 0 then
        self.pack:setCurrentUses(self.pack:getCurrentUses() - 1)
        sendItemStats(self.pack) -- syncs "uses" to clients (syncItemFields needs a 2nd arg in B42)
    end
    
    -- 2) Create the cigarette on the server and add it to the player's inventory.
    local singleCig = instanceItem("Base.CigaretteSingle")
    self.character:getInventory():AddItem(singleCig)
    sendAddItemToContainer(self.character:getInventory(), singleCig)
    local cigID = singleCig:getID()
    
    if isServer() then
        -- Multiplayer: tell the client to start the smoking sequence with this cigarette.
        local args = {
            onlineID = self.character:getOnlineID(),
            cigID = cigID,
            useCar = self.useCar,
        }
        if self.heatSource then
            local sq = self.heatSource:getSquare()
            args.heatSource = {
                x = sq:getX(),
                y = sq:getY(),
                z = sq:getZ(),
                objectName = self.heatSource:getObjectName(),
            }
        end
        sendServerCommand(self.character, "IDNAL", "StartSmokingSequence", args)
    else
        -- Singleplayer: client code is available in this process, start the chain directly.
        if self.useCar then
            OnCarSmoking(self.character, singleCig)
        elseif self.heatSource then
            IDNALOnStoveSmoking(self.character, self.heatSource, singleCig)
        end
    end
    return true
end

function IDNALTakeCigarette:new(character, heatSource, pack, useCar)
    local o = ISBaseTimedAction.new(self, character)
    o.heatSource = heatSource
    o.useCar = useCar or false
    o.pack = pack
    o.maxTime = o:getDuration()
    o.stopOnWalk = false
    o.stopOnRun = true
    return o
end
