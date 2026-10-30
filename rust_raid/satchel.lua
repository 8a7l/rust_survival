-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/satchel.lua

local S = minetest.get_translator("rust_raid")
local settings = minetest.settings
local DEFAULTS = {damage = 100, radius = 3, fuse = 5}
local DAMAGE = tonumber(settings:get("rust_raid_satchel_damage")) or DEFAULTS.damage
local RADIUS = tonumber(settings:get("rust_raid_satchel_radius")) or DEFAULTS.radius
local FUSE   = tonumber(settings:get("rust_raid_satchel_fuse"))   or DEFAULTS.fuse

local get_node    = minetest.get_node
local set_node    = minetest.set_node
local remove_node = minetest.remove_node
local get_meta    = minetest.get_meta
local get_node_timer = minetest.get_node_timer
local chat_send   = minetest.chat_send_player

local TEX_ITEM  = "rust_raid_satchel_front.png"
local TEX_ARMED = {
    "rust_raid_satchel_top.png",
    "rust_raid_satchel_bottom.png",
    "rust_raid_satchel_right.png",
    "rust_raid_satchel_left.png",
    "rust_raid_satchel_back.png",
    "rust_raid_satchel_front.png"
}

minetest.register_node("rust_raid:satchel_armed", {
    description = S("Armed Satchel Charge"),
    tiles = TEX_ARMED,
    is_ground_content = false,
    walkable = false,
    pointable = true,
    diggable = true,
    drop = "rust_raid:satchel",
    paramtype = "light",
    groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},

    on_timer = function(pos, elapsed)
        local node = get_node(pos)
        if node.name ~= "rust_raid:satchel_armed" then return false end
        local placer = get_meta(pos):get_string("placer")
        rust_raid.explode(pos, RADIUS, DAMAGE, "satchel", placer)
        if get_node(pos).name == "rust_raid:satchel_armed" then
            remove_node(pos)
        end
    end,
})

minetest.register_craftitem("rust_raid:satchel", {
    description = S("Satchel Charge (@1s, @2 dmg, r=@3)", FUSE, DAMAGE, RADIUS),
    inventory_image = TEX_ITEM,
    stack_max = 5,

    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos = pointed_thing.above
        if get_node(pos).name ~= "air" then return itemstack end

        set_node(pos, {name = "rust_raid:satchel_armed"})
        local meta = get_meta(pos)

        if user and user:is_player() then
            local pname = user:get_player_name()
            meta:set_string("placer", pname)
            if not rust_hardcore.is_raid_window() then
                chat_send(pname, S("[Rust Survival] Warning: raid window closed. DUD!"))
            end
            chat_send(pname, S("[Rust Survival] Satchel armed, fuse @1s", FUSE))
        end

        get_node_timer(pos):start(FUSE)
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_craft({
    output = "rust_raid:satchel",
    recipe = {{"rust_raid:gunpowder", "rust_raid:gunpowder"}, {"rust_raid:gunpowder", "default:paper"}},
})

rust_core.log("action", string.format("Satchel registered (%ds, %d dmg)", FUSE, DAMAGE))