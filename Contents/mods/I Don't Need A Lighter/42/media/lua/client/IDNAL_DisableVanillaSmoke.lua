-- Replace vanilla smoke menu logic with our own Fire Source check
-- Smoke option should only be enabled if player has a Fire Source item in inventory or a valid heat source nearby
require "shared/IDNALUtils"

-- Recherche d'une source de chaleur autour du joueur (rayon 2)
local function FindNearbyHeatSource(player)
    local square = player:getSquare()
    if not square then return nil end
    local playerIsOutside = player:isOutside() or (square.isOutside and square:isOutside())
    local bestObj = nil
    local bestPriority = 99
    for dx = -2, 2 do
        for dy = -2, 2 do
            local sq = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
            if sq then
                local sqIsOutside = sq.isOutside and sq:isOutside()
                local valid = false
                if playerIsOutside then
                    valid = sqIsOutside
                else
                    valid = not sqIsOutside
                end
                if valid then
                    for i = 0, sq:getObjects():size() - 1 do
                        local obj = sq:getObjects():get(i)
                        if IDNALIsValidHeatSource then
                            local result = IDNALIsValidHeatSource(obj)
                            if result.valid and result.priority < bestPriority then
                                bestObj = obj
                                bestPriority = result.priority
                            end
                        end
                    end
                end
            end
        end
    end
    return bestObj
end


local function GetFirstItem(items)
    if not items or #items == 0 then return nil end
    local entry = items[1]
    if type(entry) == "table" and entry.items then
        return entry.items[1]
    end
    return entry
end

-- Smoke a loose cigarette using a fire source (lighter/matches) carried in the
-- player's inventory. Used after a cigarette has been taken out of a pack.
-- (A CigaretteSingle is a proper Food item, unlike a CigarettePack, so the
-- vanilla eat action handles it fine.)
function IDNALOnLighterSmoking(player, cigarette)
    if not player or not cigarette then return end
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.eatItem then
        ISInventoryPaneContextMenu.eatItem(cigarette, 1, player:getPlayerNum())
    end
end

-- Returns the first carried item that the game would actually accept to light the
-- given cigarette, i.e. one whose full type is listed in the cigarette's
-- RequireInHandOrInventory (lighters, matches, ...). Items that only carry the
-- START_FIRE tag but are not valid lighters (e.g. a MagnesiumFirestarter) are
-- therefore ignored, instead of enabling a Smoke option that always fails.
local function FindSmokingFireSource(player, cigarette)
    if not player or not cigarette or not cigarette.getRequireInHandOrInventory then return nil end
    local types = cigarette:getRequireInHandOrInventory()
    if not types then return nil end
    local inventory = player:getInventory()
    if not inventory then return nil end
    for i = 1, types:size() do
        local fullType = moduleDotType(cigarette:getModule(), types:get(i - 1))
        local found = inventory:getFirstTypeRecurse(fullType)
        if found then
            IDNALDebugPrint("Found usable fire source: " .. tostring(found:getType()))
            return found
        end
    end
    return nil
end

local function ReplaceVanillaSmokeMenu(playerIndex, context, items)
    if not context or not context.options then return end
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    -- Only handle smokable items (cigarettes, cigarillos, etc.)
    -- This avoids issues with Turkish where "Smoke" and "Drink" share the same translation "İç"
    local firstItem = GetFirstItem(items)
    if not IDNALIsSmokable(firstItem) then return end

   
    local fireSourceItem = FindSmokingFireSource(player, firstItem)
    local hasFireSource = fireSourceItem ~= nil
    local heatSource = nil
    if _G.IDNALIsValidHeatSource then
        heatSource = FindNearbyHeatSource(player)
    end
    -- Can we smoke with the car's cigarette lighter? (must be in a front seat with power & ignition)
    local canUseCarLighter = false
    local vehicle = player:getVehicle()
    if vehicle then
        local seat = vehicle:getSeat(player)
        if (seat == 0 or seat == 1) and vehicle:getBatteryCharge() > 0 and (vehicle:isHotwired() or vehicle:isKeysInIgnition()) then
            canUseCarLighter = true
        end
    end

    -- Find the "Smoke" option by localized name (safe now since we confirmed it's a smokable item)
    local vanillaSmoke = context:getOptionFromName(getText("ContextMenu_Smoke"))
    if not vanillaSmoke then
        -- fallback: scan all options for the translated name
        for i = 1, #context.options do
            local option = context.options[i]
            if option and option.name then
                if option.name == getText("ContextMenu_Smoke") then
                    vanillaSmoke = option
                    break
                end
            end
        end
    end
    if vanillaSmoke then
        local insertAfter = nil
        for i = 1, #context.options do
            if context.options[i] == vanillaSmoke and i > 1 then
                insertAfter = context.options[i-1].name
                break
            end
        end
        context:removeOptionByName(vanillaSmoke.name)

                local optionLabel = getText('ContextMenu_Smoke')
        if canUseCarLighter then
            optionLabel = optionLabel .. " (" .. getText('ContextMenu_CarLighter') .. ")"
        elseif heatSource then
            local heatName = IDNALGetHeatSourceLabel(heatSource)
            optionLabel = optionLabel .. " (" .. tostring(heatName) .. ")"
        elseif hasFireSource then
            -- Name of the valid fire source we will actually use (ex: "Lighter", "Matches")
            local fireSourceName = fireSourceItem:getDisplayName() or fireSourceItem:getName() or fireSourceItem:getType()
            if fireSourceName then
                optionLabel = getText('ContextMenu_Smoke') .. " (" .. tostring(fireSourceName) .. ")"
            end
        end

        local customFunc, tooltip, notAvailable
        if canUseCarLighter then
            customFunc = function()
                local smokable = nil
                if items and #items > 0 then
                    if type(items[1]) == "table" and items[1].items then
                        smokable = items[1].items[1]
                    else
                        smokable = items[1]
                    end
                end
                if not player or not smokable then return end

                if smokable:getType() == "CigarettePack" then
                    -- Take one cigarette from the pack, then smoke it with the car lighter
                    IDNALStartPackSmoking(player, smokable, nil, true)
                else
                    OnCarSmoking(player, smokable)
                end
            end
            tooltip = nil
            notAvailable = false
        elseif heatSource then
            customFunc = function()
                local smokable = nil
                if items and #items > 0 then
                    if type(items[1]) == "table" and items[1].items then
                        smokable = items[1].items[1]
                    else
                        smokable = items[1]
                    end
                end
                if not player or not heatSource or not smokable then return end
                
                if smokable:getType() == "CigarettePack" then
                    -- Run vanilla "Take Cigarette" recipe, then queue smoking pipeline
                    IDNALStartPackSmoking(player, smokable, heatSource, false)
                else
                    IDNALOnStoveSmoking(player, heatSource, smokable)
                end
            end
            tooltip = nil
            notAvailable = false
        elseif hasFireSource then
            customFunc = function()                
                local smokable = nil
                if items and #items > 0 then
                    if type(items[1]) == "table" and items[1].items then
                        smokable = items[1].items[1]
                    else
                        smokable = items[1]
                    end
                end
                if not player or not smokable then return end

                if smokable:getType() == "CigarettePack" then
                    -- A CigarettePack is not a Food item, so it must never be handed to
                    -- the vanilla eat action (ISEatFoodAction:getDuration would call a
                    -- nil getBaseHunger). Take a cigarette out with our own pipeline
                    -- first; the extracted single cigarette is smoked afterwards.
                    IDNALStartPackSmoking(player, smokable, nil, false)
                elseif ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.eatItem then
                    ISInventoryPaneContextMenu.eatItem(smokable, 1, playerIndex)
                end
            end
            tooltip = nil
            notAvailable = false
        else
            customFunc = function() end
            tooltip = ISToolTip:new()
            tooltip:setName("Need Fire Source")
            tooltip.description = "You need a fire source (lighter, matches, stove, etc.) to smoke."
            notAvailable = true
        end

                local customOption
        if insertAfter then
            customOption = context:insertOptionAfter(insertAfter, optionLabel, nil, customFunc)
        else
            customOption = context:addOptionOnTop(optionLabel, nil, customFunc)
        end
        if firstItem and firstItem.getTexture then
            customOption.iconTexture = firstItem:getTexture()
        end
        customOption.notAvailable = notAvailable
        customOption.toolTip = tooltip
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ReplaceVanillaSmokeMenu)