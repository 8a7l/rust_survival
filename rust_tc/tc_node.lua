-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/tc_node.lua
-- TC node: placement, ownership, HP, info, deposit inventory.

local S = minetest.get_translator("rust_tc")
local settings = minetest.settings
local DEFAULT_HP     = tonumber(settings:get("rust_tc_hp"))     or 5000
local DEFAULT_RADIUS = tonumber(settings:get("rust_tc_radius")) or 20

local get_meta      = minetest.get_meta
local get_node      = minetest.get_node
local remove_node   = minetest.remove_node
local pos_to_string = minetest.pos_to_string
local chat_send     = minetest.chat_send_player
local raycast       = minetest.raycast
local add_item      = minetest.add_item

local ITEM_NAME = "rust_tc:cupboard"

local TEX_ITEM = "rust_tc_front.png"
local TEX_NODE = {
    "rust_tc_top.png",
    "rust_tc_bottom.png",
    "rust_tc_right.png",
    "rust_tc_left.png",
    "rust_tc_back.png",
    "rust_tc_front.png"
}

minetest.register_node(ITEM_NAME, {
    description = S("Tool Cupboard") .. "\n" ..
        S("Authorizes players in a @1-block radius", DEFAULT_RADIUS) .. "\n" ..
        S("HP: @1", DEFAULT_HP),
    tiles = TEX_NODE,
    inventory_image = TEX_ITEM,
    wield_image = TEX_ITEM,
    is_ground_content = false,
    walkable = true,
    diggable = true,
    drop = ITEM_NAME,
    groups = {
        rust_building = 1,
        rust_tier_metal = 1,
        rust_tc = 1,
    },

    on_construct = function(pos)
        local meta = get_meta(pos)
        local inv = meta:get_inventory()
        if inv:get_size("deposit") == 0 then
            inv:set_size("deposit", 1)
        end
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        return count
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname ~= "deposit" then return end
        local meta = get_meta(pos)
        local tc_id = meta:get_int("tc_id")
        if tc_id == 0 then return end
        local tc = rust_tc.tcs[tc_id]
        if not tc then return end

        local pname = player:get_player_name()
        if tc.owner ~= pname
           and not (tc.authorized and tc.authorized[pname]) then
            return
        end

        local inv = meta:get_inventory()
        local slot_stack = inv:get_stack("deposit", index)
        if slot_stack:is_empty() then return end

        local weight = rust_tc.FUEL_WEIGHTS[slot_stack:get_name()]
        if not weight then
            player:get_inventory():add_item("main", slot_stack)
            inv:set_stack("deposit", index, ItemStack(""))
            chat_send(pname, S("[Rust Survival] Not a fuel: @1", slot_stack:get_name()))
            rust_tc.show_formspec(pos, player)
            return
        end

        local points = weight * slot_stack:get_count()
        rust_tc.add_upkeep(pos, points)
        inv:set_stack("deposit", index, ItemStack(""))

        chat_send(pname, S("[Rust Survival] Deposited @1 @2 = +@3 points",
            slot_stack:get_count(), slot_stack:get_name(), points))

        rust_tc.show_formspec(pos, player)
    end,

    on_rightclick = function(pos, node, clicker, itemstack)
        if not clicker or not clicker:is_player() then return itemstack end
        rust_tc.show_formspec(pos, clicker)
        return itemstack
    end,

    after_place_node = function(pos, placer)
        if not placer or not placer:is_player() then
            remove_node(pos)
            return
        end
        local pname = placer:get_player_name()

        local meta = get_meta(pos)
        local inv = meta:get_inventory()
        if inv:get_size("deposit") == 0 then
            inv:set_size("deposit", 1)
        end

        local _, existing = rust_tc.find_tc_at(pos)
        if existing then
            chat_send(pname, S("[Rust Survival] Cannot place TC within another TC's radius (owner: @1)", existing.owner))
            remove_node(pos)
            add_item(pos, ItemStack(ITEM_NAME))
            return
        end

        local tc_id = rust_tc.next_id()
        local now = os.time()
        -- Початкова ціна утримання (0 блоків)
        local cost = rust_tc.upkeep_cost(DEFAULT_RADIUS, 0)
        
        local data = {
            owner        = pname,
            pos          = {x = pos.x, y = pos.y, z = pos.z},
            radius       = DEFAULT_RADIUS,
            authorized   = {},
            created_at   = now,
            upkeep_pool  = cost,
            last_tick    = now,
            decay_pending = 0,
            block_count  = 0, -- <--- ДОДАНО
        }
        rust_tc.save(tc_id, data)

        meta:set_int("tc_id", tc_id)
        meta:set_int("rust_hp", DEFAULT_HP)
        meta:set_int("wipe_gen", rust_core.get_wipe_gen())

        chat_send(pname, S("[Rust Survival] TC #@1 placed, radius @2, HP @3, upkeep @4/hr",
            tc_id, DEFAULT_RADIUS, DEFAULT_HP, cost))
    end,

    on_destruct = function(pos)
        local meta = get_meta(pos)
        local tc_id = meta:get_int("tc_id")
        if tc_id > 0 then
            rust_tc.delete(tc_id)
        end
    end,
})

minetest.register_craft({
    output = ITEM_NAME,
    recipe = {
        {"default:wood",  "default:stone", "default:wood"},
        {"default:wood",  "default:steel_ingot", "default:wood"},
        {"default:stone", "default:stone", "default:stone"},
    },
})

function rust_tc.find_for_player(pname)
    local player = minetest.get_player_by_name(pname)
    if not player then return nil end

    local pos = player:get_pos()
    local p = {x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z)}
    local id, tc = rust_tc.find_tc_at(p)
    if id then return id, tc end

    local dir = player:get_look_dir()
    local target = {x = pos.x + dir.x * 8, y = pos.y + dir.y * 8, z = pos.z + dir.z * 8}
    local ray = raycast(pos, target):next()
    if ray and ray.type == "node" then
        local node = get_node(ray.under)
        if node.name == ITEM_NAME then
            local tc_id = get_meta(ray.under):get_int("tc_id")
            if tc_id > 0 and rust_tc.tcs[tc_id] then
                return tc_id, rust_tc.tcs[tc_id]
            end
        end
    end

    return nil
end

rust_core.log("action", "TC node registered (HP=" .. DEFAULT_HP ..
    ", radius=" .. DEFAULT_RADIUS .. ", custom 6-sided textures)")