-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/protection.lua

local S = minetest.get_translator("rust_tc")
local settings = minetest.settings
local PROTECT_ENABLED = settings:get_bool("rust_tc_protect_enabled", true)
local DEBUG_LOG       = settings:get_bool("rust_tc_debug_log", false)

local CONTAINER_NAMES = {
    ["default:chest"]          = true,
    ["default:chest_locked"]   = true,
    ["default:furnace"]        = true,
    ["default:furnace_active"] = true,
}

local function is_container(name)
    if CONTAINER_NAMES[name] then return true end
    if minetest.get_item_group(name, "door") > 0 then return true end
    if minetest.get_item_group(name, "gate") > 0 then return true end
    return false
end

minetest.register_on_mods_loaded(function()
    if not PROTECT_ENABLED then
        rust_core.log("action", "TC protection DISABLED by setting")
        return
    end

    local click_wrapped = 0
    for name, def in pairs(minetest.registered_nodes) do
        if is_container(name) and def.on_rightclick then
            local orig = def.on_rightclick
            def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
                if clicker and clicker:is_player() then
                    local pname = clicker:get_player_name()
                    if not rust_tc.can_access(pos, pname) then
                        minetest.chat_send_player(pname,
                            S("[Rust Survival] Not authorized (TC-protected area)"))
                        return itemstack
                    end
                end
                return orig(pos, node, clicker, itemstack, pointed_thing)
            end
            click_wrapped = click_wrapped + 1
        end
    end

    rust_core.log("action", "Wrapped " .. click_wrapped ..
        " containers (right-click) with TC authorization")
end)

-- ============================================================
-- Block Counting (Placement & Protection)
-- ============================================================
if PROTECT_ENABLED then
    minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack)
        if not placer or not placer:is_player() then return end
        
        -- Перевірка на захист будівництва
        if rust_building.is_building(newnode.name) and newnode.name ~= "rust_tc:cupboard" then
            local pname = placer:get_player_name()
            if not rust_tc.can_access(pos, pname) then
                minetest.remove_node(pos)
                placer:get_inventory():add_item("main", ItemStack(newnode.name))
                minetest.chat_send_player(pname,
                    S("[Rust Survival] Cannot place here (TC-protected area)"))
                return
            end
        end
        
        -- Підрахунок блоків для утримання (при встановленні)
        if rust_building.is_building(newnode.name) then
            local tc_id, tc = rust_tc.find_tc_at(pos)
            if tc_id and tc then
                tc.block_count = (tc.block_count or 0) + 1
                rust_tc.save(tc_id, tc)
                rust_core.log("action", "Block placed in TC #" .. tc_id .. ". Total blocks: " .. tc.block_count)
            end
        end
    end)
    rust_core.log("action", "Placement protection & block counting registered")
end