-- Replace vanilla smoke menu logic with our own Fire Source check
-- Smoke option should only be enabled if player has a Fire Source item in inventory or a valid heat source nearby
require "shared/IDNALUtils"

-- Check if player has any fire source in inventory
local function HasFireSource(player)
    local inventory = player:getInventory()
    if not inventory then return false end
    
    -- Check for items with START_FIRE tag (lighters, matches, etc.)
    for i = 0, inventory:getItems():size() - 1 do        
        local item = inventory:getItems():get(i)
        if item and item:hasTag(ItemTag.START_FIRE) then            
            IDNALDebugPrint("Found item with START_FIRE tag: " .. item:getType())
            return true
        end        
    end

    for i=0, inventory:getItems():size()-1 do	
		if inventory:getItems():get(i):getCategory() == ("Container") then            
            --We look inside each container for fire source
            local ContainerContent = inventory:getItems():get(i):getItemContainer():getItems()
            for j=0, ContainerContent:size()-1 do                
                local item = ContainerContent:get(j)
                if item and item:hasTag(ItemTag.START_FIRE) then
                    IDNALDebugPrint("Found item with START_FIRE tag in container: " .. item:getType())
                    return true
                end
            end
        end        
    end

    return false
end

-- Recherche d'une source de chaleur autour du joueur (rayon 4)
local function FindNearbyHeatSource(player)
    local square = player:getSquare()
    if not square then return nil end
    local playerIsOutside = player:isOutside() or (square.isOutside and square:isOutside())
    for dx = -4, 4 do
        for dy = -4, 4 do
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
                        if IDNALIsValidHeatSource and IDNALIsValidHeatSource(obj).valid then
                            return obj
                        end
                    end
                end
            end
        end
    end
    return nil
end


local function ReplaceVanillaSmokeMenu(playerIndex, context, items)
    if not context or not context.options then return end
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local hasFireSource = HasFireSource(player)
    local heatSource = nil
    if _G.IDNALIsValidHeatSource then
        heatSource = FindNearbyHeatSource(player)
    end

    -- Suppression propre de l'option vanilla "Smoke"
    local vanillaSmoke = context:getOptionFromName("Smoke")
    if not vanillaSmoke then
        -- fallback : recherche par traduction ou nom approché
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
        
        --TEMP FIX FOR NOW LET'S CHECK IF WE CLICKED ON A PACK OF CIGARETTES OR A CIGARETTE
        --IF A PACK IS FOUND THEN LET'S REMOVE THE SMOKE OPTION ALL TOGETHER
        if items and #items > 0 then
            if type(items[1]) == "table" and items[1].items then
                if items[1].items[1]:getType() == "CigarettePack" then return end
            end
        end
        --END TEMP FIX

        local optionLabel = vanillaSmoke.name
        if heatSource then
            local heatName = IDNALGetHeatSourceLabel(heatSource)
            optionLabel = getText('ContextMenu_Smoke') .. " (" .. tostring(heatName) .. ")"
        elseif hasFireSource then
            -- Chercher le nom de la source de feu utilisée (ex : "Lighter", "Matches")
            local fireSourceName = nil
            local inventory = player:getInventory()
            for i = 0, inventory:getItems():size() - 1 do
                local item = inventory:getItems():get(i)
                if item and item:hasTag(ItemTag.START_FIRE) then
                    fireSourceName = item:getDisplayName() or item:getName() or item:getType()
                    break
                end
            end
            if not fireSourceName then
                for i = 0, inventory:getItems():size() - 1 do
                    if inventory:getItems():get(i):getCategory() == ("Container") then
                        local ContainerContent = inventory:getItems():get(i):getItemContainer():getItems()
                        for j = 0, ContainerContent:size() - 1 do
                            local item = ContainerContent:get(j)
                            if item and item:hasTag(ItemTag.START_FIRE) then
                                fireSourceName = item:getDisplayName() or item:getName() or item:getType()
                                break
                            end
                        end
                        if fireSourceName then break end
                    end
                end
            end
            if fireSourceName then
                optionLabel = getText('ContextMenu_Smoke') .. " (" .. tostring(fireSourceName) .. ")"
            end
        end

        local customFunc, tooltip, notAvailable
        if heatSource then
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
                IDNALOnStoveSmoking(player, heatSource, smokable)
            end
            tooltip = nil
            notAvailable = false
        elseif hasFireSource then
            customFunc = function()
                local smokables = items
                if type(smokables) ~= "table" or (smokables[1] and smokables[1].items) then
                    if smokables and #smokables > 0 and type(smokables[1]) == "table" and smokables[1].items then
                        smokables = smokables[1].items
                    else
                        smokables = {smokables}
                    end
                end
                for _, smokable in ipairs(smokables) do
                    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.eatItem then
                        ISInventoryPaneContextMenu.eatItem(smokable, 1, playerIndex)
                    end
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
        customOption.notAvailable = notAvailable
        customOption.toolTip = tooltip
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ReplaceVanillaSmokeMenu)