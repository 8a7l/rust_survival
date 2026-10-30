-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/c4.lua

local S = minetest.get_translator("rust_raid")
local settings = minetest.settings
local DEFAULTS = {damage = 500, radius = 4, fuse = 3}
local DAMAGE = tonumber(settings:get("rust_raid_c4_damage")) or DEFAULTS.damage
local RADIUS = tonumber(settings:get("rust_raid_c4_radius")) or DEFAULTS.radius
local FUSE   = tonumber(settings:get("rust_raid_c4_fuse"))   or DEFAULTS.fuse

local get_node    = minetest.get_node
local set_node    = minetest.set_node
local remove_node = minetest.remove_node
local get_meta    = minetest.get_meta
local get_node_timer = minetest.get_node_timer
local chat_send   = minetest.chat_send_player

local TEX_ITEM  = "rust_raid_c4_front.png"
local TEX_ARMED = {
    "rust_raid_c4_top.png",
    "rust_raid_c4_bottom.png",
    "rust_raid_c4_right.png",
    "rust_raid_c4_left.png",
    "rust_raid_c4_back.png",
    "rust_raid_c4_front.png"
}

minetest.register_node("rust_raid:c4_armed", {
    description = S("Armed C4"),
    tiles = TEX_ARMED,
    is_ground_content = false,
    walkable = false,
    pointable = true,
    diggable = true,
    drop = "rust_raid:c4",
    paramtype = "light",
    groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},

    on_timer = function(pos, elapsed)
        local node = get_node(pos)
        if node.name ~= "rust_raid:c4_armed" then return false end
        local placer = get_meta(pos):get_string("placer")
        rust_raid.explode(pos, RADIUS, DAMAGE, "c4", placer)
        if get_node(pos).name == "rust_raid:c4_armed" then
            remove_node(pos)
        end
    end,
})

minetest.register_craftitem("rust_raid:c4", {
    description = S("C4 (@1s, @2 dmg, r=@3)", FUSE, DAMAGE, RADIUS),
    inventory_image = TEX_ITEM,
    stack_max = 3,

    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos = pointed_thing.above
        if get_node(pos).name ~= "air" then return itemstack end

        set_node(pos, {name = "rust_raid:c4_armed"})
        local meta = get_meta(pos)

        if user and user:is_player() then
            local pname = user:get_player_name()
            meta:set_string("placer", pname)
            if not rust_hardcore.is_raid_window() then
                chat_send(pname, S("[Rust Survival] Warning: raid window closed. DUD!"))
            end
            chat_send(pname, S("[Rust Survival] C4 armed, fuse @1s", FUSE))
        end

        get_node_timer(pos):start(FUSE)
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_craft({
    output = "rust_raid:c4",
    recipe = {
        {"rust_raid:gunpowder", "rust_raid:gunpowder", "rust_raid:gunpowder"},
        {"default:steel_ingot", "default:diamond",     "default:steel_ingot"},
        {"rust_raid:gunpowder", "rust_raid:gunpowder", "rust_raid:gunpowder"},
    },
})

rust_core.log("action", string.format("C4 registered (%ds, %d dmg)", FUSE, DAMAGE))