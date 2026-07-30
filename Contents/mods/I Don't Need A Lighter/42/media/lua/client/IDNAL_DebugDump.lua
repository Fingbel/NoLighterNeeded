-- IDNAL Debug Dump - Enable by setting IDNAL_DEBUG = true in IDNALUtils.lua
-- Logs the structure of items and context menu when right-clicking inventory

-- Helper: dump key properties of a context option (compact)
local function DumpOption(opt, indent)
    if not opt then return end
    local compact = {"name", "notAvailable", "onSelect", "target", "param1", "param2", "param3", "subOption", "id"}
    for _, f in ipairs(compact) do
        local v = opt[f]
        if v ~= nil then
            if type(v) == "function" then
                print(indent .. f .. " = function")
            elseif type(v) == "table" then
                print(indent .. f .. " = table (#" .. tostring(#v) .. ")")
            elseif type(v) == "userdata" then
                local name = tostring(v)
                local ok, dn = pcall(function()
                    if v.getDisplayName then return v:getDisplayName() end
                end)
                if ok and dn then name = dn
                else
                    ok, dn = pcall(function()
                        if v.getName then return v:getName() end
                    end)
                    if ok and dn then name = dn
                    else
                        ok, dn = pcall(function()
                            if v.getType then return v:getType() end
                        end)
                        if ok and dn then name = dn end
                    end
                end
                print(indent .. f .. " = " .. tostring(name))
            else
                print(indent .. f .. " = " .. tostring(v))
            end
        end
    end
    -- Show all option keys
    local keys = {}
    for k, _ in pairs(opt) do if type(k) == "string" then table.insert(keys, k) end end
    if #keys > 0 then table.sort(keys); print(indent .. "-- keys: " .. table.concat(keys, ", ")) end
end

local function DumpRightClick(playerIndex, context, items)
    if not IDNAL_DEBUG then return end

    print("========== IDNAL DEBUG: OnFillInventoryObjectContextMenu ==========")
    print("playerIndex=" .. tostring(playerIndex))

    -- instanceMap overview
    print("--- instanceMap:")
    if type(context) == "table" and context.instanceMap then
        for k, v in pairs(context.instanceMap) do
            print("  [" .. tostring(k) .. "] -> " .. tostring(#(v.options or {})) .. " options")
        end
    end

    -- Only show Smoke (4) and Cigarette Pack (5) options + their sub-options
    print("--- Relevant options ---")
    for i = 1, #context.options do
        local opt = context.options[i]
        if opt and (opt.name == "Smoke" or opt.name == "Cigarette Pack" or opt.name == "More") then
            print("  [" .. i .. "] '" .. tostring(opt.name) .. "'")
            DumpOption(opt, "    ")
            -- Dump its submenu from instanceMap
            if opt.subOption and context.instanceMap and context.instanceMap[opt.subOption] then
                local sub = context.instanceMap[opt.subOption]
                print("    -> subOption [" .. tostring(opt.subOption) .. "]:")
                for si = 1, #sub.options do
                    local sopt = sub.options[si]
                    if sopt then
                        print("      [" .. si .. "] '" .. tostring(sopt.name) .. "'")
                        DumpOption(sopt, "        ")
                    end
                end
            end
        end
    end

    -- Quick items summary
    if items then
        print("--- Items (#" .. tostring(#items) .. ") ---")
        for i = 1, #items do
            local entry = items[i]
            if type(entry) == "userdata" then
                local ok, typ, name = pcall(function() return entry:getType(), entry:getDisplayName() end)
                if ok then print("  [" .. i .. "] " .. tostring(typ) .. " | " .. tostring(name)) end
            elseif type(entry) == "table" and entry.items then
                for j = 1, #entry.items do
                    local sub = entry.items[j]
                    if sub then
                        local ok, typ, name = pcall(function() return sub:getType(), sub:getDisplayName() end)
                        if ok then print("  [" .. i .. "][" .. j .. "] " .. tostring(typ) .. " | " .. tostring(name)) end
                    end
                end
            end
        end
    end

    -- ===== TEST: Call onSelect for "Take Cigarette" =====
    -- if context.instanceMap and context.instanceMap[3] and context.instanceMap[3].options then
    --     for si = 1, #context.instanceMap[3].options do
    --         local subOpt = context.instanceMap[3].options[si]
    --         if subOpt and subOpt.name == "Take Cigarette" and subOpt.onSelect then
    --             print("=== TEST: Calling onSelect for '" .. tostring(subOpt.name) .. "' ===")
    --             local ok, result = pcall(function()
    --                 return subOpt.onSelect(subOpt.target, subOpt.param1, subOpt.param2)
    --             end)
    --             print("  ok=" .. tostring(ok) .. ", result=" .. tostring(result))

    --             -- Probe recipe for output items
    --             if subOpt.toolTip and subOpt.toolTip.recipe then
    --                 local recipe = subOpt.toolTip.recipe
    --                 print("  Recipe details:")
    --                 local okName, rname = pcall(function() return recipe:getName() end)
    --                 if okName then print("    getName() = " .. tostring(rname)) end
                    
    --                 local okCnt, cnt = pcall(function() return recipe:getOutputCount() end)
    --                 if okCnt then print("    getOutputCount() = " .. tostring(cnt)) end
                    
    --                 local outs
    --                 local okOuts = pcall(function() outs = recipe:getOutputs() end)
    --                 if okOuts and outs ~= nil then
    --                     print("    getOutputs() type: " .. type(outs))
    --                     local size
    --                     pcall(function() size = outs:size() end)
    --                     if size then
    --                         print("    list:size() = " .. tostring(size))
    --                         -- Try: direct numeric indexing (Java lists support it in Kahlua)
    --                         for idx = 0, size - 1 do
    --                             local outScript
    --                             local okGet = pcall(function() outScript = outs[idx] end)
    --                             if not okGet or not outScript then
    --                                 okGet = pcall(function() outScript = outs:get(idx) end)
    --                             end
    --                             if outScript then
    --                                 local item
    --                                 pcall(function() if outScript.getItem then item = outScript:getItem() end end)
    --                                 local amt
    --                                 pcall(function() if outScript.getAmount then amt = outScript:getAmount() end end)
    --                                 if item then
    --                                     local dn, tp = tostring(item), ""
    --                                     pcall(function() if item.getDisplayName then dn = item:getDisplayName() end end)
    --                                     pcall(function() if item.getType then tp = item:getType() end end)
    --                                     print("      [" .. idx .. "] Item: " .. tostring(dn) .. " | Type: " .. tostring(tp) .. " | Amount: " .. tostring(amt or "?"))
    --                                 else
    --                                     print("      [" .. idx .. "] (probing OutputScript methods)")
    --                                     local methods = {
    --                                         "getFullType", "getType", "getName",
    --                                         "getAmount", "getIntAmount", "getMaxAmount",
    --                                         "getOriginalLine", "getResourceType",
    --                                         "getChance", "getPossibleResultItems",
    --                                         "getItem", "getCreateToItemScript",
    --                                         "hasCreateToItem", "getItemApplyMode"
    --                                     }
    --                                     for _, m in ipairs(methods) do
    --                                         local okM, resM = pcall(function()
    --                                             if outScript[m] then return outScript[m](outScript) end
    --                                         end)
    --                                         if okM and resM ~= nil then
    --                                             local resStr
    --                                             if type(resM) == "userdata" then
    --                                                 local dn
    --                                                 pcall(function() if resM.getDisplayName then dn = resM:getDisplayName() end end)
    --                                                 if not dn then pcall(function() if resM.getName then dn = resM:getName() end end) end
    --                                                 if not dn then pcall(function() if resM.getType then dn = resM:getType() end end) end
    --                                                 resStr = tostring(resM) .. " (" .. tostring(dn or "?") .. ")"
    --                                             elseif type(resM) == "table" then
    --                                                 local count = 0
    --                                                 pcall(function()
    --                                                     for _ in ipairs(resM) do count = count + 1 end
    --                                                 end)
    --                                                 resStr = "table (#" .. tostring(count) .. ")"
    --                                             else
    --                                                 resStr = tostring(resM)
    --                                             end
    --                                             print("        ." .. m .. "() = " .. resStr)
    --                                         end
    --                                     end
    --                                 end
    --                             else
    --                                 print("      [" .. idx .. "] (failed to get outputScript, okGet=" .. tostring(okGet) .. ")")
    --                             end
    --                         end
    --                     end
    --                 end
                    
    --                 local okInCnt, inCnt = pcall(function() return recipe:getInputCount() end)
    --                 if okInCnt then print("    getInputCount() = " .. tostring(inCnt)) end
    --                 local okIns, ins = pcall(function() return recipe:getInputs() end)
    --                 if okIns and ins ~= nil then
    --                     print("    getInputs() type: " .. type(ins))
    --                     local size
    --                     pcall(function() size = ins:size() end)
    --                     if size then
    --                         print("    list:size() = " .. tostring(size))
    --                         for idx = 0, size - 1 do
    --                             local inScript
    --                             local okGet = pcall(function() inScript = ins[idx] end)
    --                             if not okGet or not inScript then
    --                                 okGet = pcall(function() inScript = ins:get(idx) end)
    --                             end
    --                             if inScript then
    --                                 local item
    --                                 pcall(function() if inScript.getItem then item = inScript:getItem() end end)
    --                                 if item then
    --                                     local dn, tp = tostring(item), ""
    --                                     pcall(function() if item.getDisplayName then dn = item:getDisplayName() end end)
    --                                     pcall(function() if item.getType then tp = item:getType() end end)
    --                                     print("      [" .. idx .. "] Item: " .. tostring(dn) .. " | Type: " .. tostring(tp))
    --                                 else
    --                                     print("      [" .. idx .. "] (no item) script type: " .. type(inScript))
    --                                 end
    --                             end
    --                         end
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- ===== END TEST =====

    print("================================================================")
end

Events.OnFillInventoryObjectContextMenu.Add(DumpRightClick)




