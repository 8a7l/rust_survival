-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_building/debug.lua
-- Chat commands for diagnosing can_dig / dig behaviour.
-- These are the equivalent of the /lua one-liners I gave earlier,
-- but as proper mod commands so they always work.

local pos_to_string = minetest.pos_to_string
local round = vector.round

local function block_under_player(player)
    local pos = round(player:get_pos())
    pos.y = pos.y - 1
    return pos
end

-- ============================================================
-- /rust_debug_block — inspect block under player
-- ============================================================
minetest.register_chatcommand("rust_debug_block", {
    description = "Inspect the block under you (diggable, can_dig, HP, TC)",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local pos = block_under_player(player)
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        local meta = minetest.get_meta(pos)
        local lines = {
            "=== Block under " .. name .. " ===",
            "Pos: " .. pos_to_string(pos),
            "Node: " .. node.name,
            "Registered: " .. tostring(def ~= nil),
            "diggable: " .. tostring(def and def.diggable),
            "can_dig fn present: " .. tostring(def and def.can_dig ~= nil),
            "HP in meta: " .. tostring(meta:get_int("rust_hp")),
        }
        if def and def.can_dig then
            local ok, result = pcall(def.can_dig, pos, player)
            lines[#lines+1] = "can_dig() result: " ..
                tostring(ok and result or ("ERROR: " .. tostring(result)))
        end
        if rust_tc and rust_tc.find_tc_at then
            local id, tc = rust_tc.find_tc_at(pos)
            lines[#lines+1] = "TC in radius: " .. tostring(id) ..
                (tc and (" owner=" .. tc.owner) or "")
        end
        lines[#lines+1] = "Has bypass priv: " .. tostring(
            minetest.check_player_privs(name, "protection_bypass"))
        minetest.chat_send_player(name, table.concat(lines, "\n"))
        return true
    end,
})

-- ============================================================
-- /rust_debug_player_dig — dig block under player as if mining
-- This is the REAL player dig path: goes through can_dig, then on_dignode.
-- ============================================================
minetest.register_chatcommand("rust_debug_player_dig", {
    description = "Dig block under you (real player dig path)",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local pos = block_under_player(player)
        local node = minetest.get_node(pos)
        local before_name = node.name
        local ok, err = pcall(minetest.node_dig, pos, node, player)
        local after = minetest.get_node(pos)
        return true, string.format(
            "node_dig: ok=%s err=%s | before=%s | after=%s",
            tostring(ok), tostring(err), before_name, after.name)
    end,
})

-- ============================================================
-- /rust_debug_force_dig — bypass can_dig, call dig_node directly
-- Tests whether on_dignode (audit) restores the block.
-- ============================================================
minetest.register_chatcommand("rust_debug_force_dig", {
    description = "Force dig_node on block under you (tests audit restore)",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local pos = block_under_player(player)
        local node = minetest.get_node(pos)
        local before_name = node.name
        local result = minetest.dig_node(pos)
        local after = minetest.get_node(pos)
        return true, string.format(
            "dig_node returned: %s | before=%s | after=%s",
            tostring(result), before_name, after.name)
    end,
})

-- ============================================================
-- /rust_debug_privs — show all your privs
-- ============================================================
minetest.register_chatcommand("rust_debug_privs", {
    description = "Show your privileges",
    func = function(name)
        local privs = minetest.get_player_privs(name)
        local list = {}
        for p, v in pairs(privs) do
            if v then list[#list+1] = p end
        end
        table.sort(list)
        minetest.chat_send_player(name, "Privs: " .. table.concat(list, ", "))
        return true
    end,
})

rust_core.log("action", "Debug commands registered: " ..
    "/rust_debug_block, /rust_debug_player_dig, /rust_debug_force_dig, /rust_debug_privs")