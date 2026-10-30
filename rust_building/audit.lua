-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_building/audit.lua
-- Watches for foreign dig_node calls (TNT, mcl_explosions, etc.).

local S = minetest.get_translator("rust_building")
local get_node     = minetest.get_node
local set_node     = minetest.set_node
local get_meta     = minetest.get_meta
local pos_to_string = minetest.pos_to_string

minetest.register_on_dignode(function(pos, oldnode, digger)
    if not rust_building.is_building(oldnode.name) then return end

    -- Legitimate player dig
    if digger and digger:is_player() then
        if rust_building._clear_cache then
            rust_building._clear_cache(pos)
        end
        return
    end

    -- Foreign dig (restore)
    local tier = rust_building.tier_of(oldnode.name)
    local cached = rust_building._cached_hp(pos)
    local hp = cached or rust_building.get_max_hp(tier)

    set_node(pos, oldnode)
    get_meta(pos):set_int("rust_hp", hp)

    rust_core.warn("FOREIGN DESTRUCTION of " .. oldnode.name ..
        " at " .. pos_to_string(pos) ..
        " by non-player source — block restored with HP=" .. hp ..
        ". Likely a conflicting mod calling dig_node.")
end)

-- ============================================================
-- Debug command: /rust_building_damage <amount>
-- ============================================================
minetest.register_chatcommand("rust_building_damage", {
    params = S("<amount>"),
    description = S("Damage the building block you are looking at"),
    privs = {server = true},
    func = function(name, param)
        local amount = tonumber(param)
        if not amount or amount <= 0 then
            return false, S("Usage: /rust_building_damage <amount>")
        end

        local player = minetest.get_player_by_name(name)
        if not player then return false, S("Player not found") end

        local under = minetest.raycast(
            player:get_pos(),
            vector.add(player:get_pos(),
                vector.multiply(player:get_look_dir(), 8))
        ):next()
        if not under or under.type ~= "node" then
            return false, S("Look at a block within 8 nodes")
        end

        local result = rust_building.damage_node(
            under.under, amount, "debug")
        return true, S("Result: @1", result)
    end,
})

rust_core.log("action", "Audit handler registered (player digs allowed)")