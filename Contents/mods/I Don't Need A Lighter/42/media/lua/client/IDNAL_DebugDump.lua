-- IDNAL Debug Dump - Enable by setting IDNAL_DEBUG = true in IDNALUtils.lua
-- Logs the structure of items and context menu when right-clicking inventory

local function DumpRightClick(playerIndex, context, items)
    if not IDNAL_DEBUG then return end

    print("========== IDNAL DEBUG: OnFillInventoryObjectContextMenu ==========")
    print("playerIndex=" .. tostring(playerIndex))
    
    -- Dump context options (names only, for Turkish "ic" check)
    print("--- Context Options (" .. tostring(#context.options) .. " total) ---")
    for i = 1, #context.options do
        local opt = context.options[i]
        if opt then
            print("  [" .. i .. "] name='" .. tostring(opt.name) .. "' | notAvailable=" .. tostring(opt.notAvailable))
        end
    end

    -- Dump the items parameter (compact)
    print("--- Items (" .. type(items) .. ") ---")
    if items then
        print("#items = " .. tostring(#items))
        for i = 1, math.min(#items, 10) do
            local entry = items[i]
            print("  type=" .. type(entry))
            
            if type(entry) == "userdata" then
                -- Direct item
                local ok = pcall(function()
                    print("    Type=" .. entry:getType() .. " | DisplayName=" .. entry:getDisplayName() .. " | EatType=" .. tostring(entry:getEatType()) .. " | Category=" .. tostring(entry:getCategory()))
                end)
                if not ok then print("    (no item methods?)") end
                
            elseif type(entry) == "table" then
                if entry.items then
                    print("    has .items (" .. type(entry.items) .. ", #" .. tostring(#entry.items) .. ")")
                    for j = 1, math.min(#entry.items, 5) do
                        local sub = entry.items[j]
                        if sub then
                            local ok = pcall(function()
                                print("      [" .. j .. "] " .. sub:getType() .. " | " .. sub:getDisplayName() .. " | EatType=" .. tostring(sub:getEatType()) .. " | Category=" .. tostring(sub:getCategory()))
                            end)
                            if not ok then print("      [" .. j .. "] (not an item?)") end
                        end
                    end
                elseif entry.item then
                    print("    has .item")
                    local ok = pcall(function()
                        print("      " .. entry.item:getType() .. " | " .. entry.item:getDisplayName())
                    end)
                else
                    local keys = {}
                    for k, _ in pairs(entry) do table.insert(keys, tostring(k)) end
                    print("    keys: " .. table.concat(keys, ", "))
                end
            end
        end
    end
    
    print("================================================================")
end

Events.OnFillInventoryObjectContextMenu.Add(DumpRightClick)
