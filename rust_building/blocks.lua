-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_building/blocks.lua
-- Custom on_punch system. Fast for auth, blocked for raiders UNLESS block is damaged/decaying.

local S = minetest.get_translator("rust_building")
local register_node = minetest.register_node
local pos_to_string = minetest.pos_to_string
local get_node = minetest.get_node
local get_meta = minetest.get_meta

local TIERS = {
    wood = {
        description = S("Wood Block"),
        tiles       = {"default_wood.png"},
        drop        = "default:wood",
        craft       = {{"default:wood", "default:wood"},
                       {"default:wood", "default:wood"}},
    },
    stone = {
        description = S("Stone Block"),
        tiles       = {"default_stone.png"},
        drop        = "default:stone",
        craft       = {{"default:stone", "default:stone"},
                       {"default:stone", "default:stone"}},
    },
    metal = {
        description = S("Metal Block"),
        tiles       = {"default_steel_block.png"},
        drop        = "default:steel_ingot",
        craft       = {{"default:steel_ingot", "default:steel_ingot"},
                       {"default:steel_ingot", "default:steel_ingot"}},
    },
    armored = {
        description = S("Armored Block"),
        tiles       = {"default_steel_block.png^[colorize:#3A3A3A:180"},
        drop        = "default:steel_ingot",
        craft       = {{"default:steel_ingot", "default:diamond",
                        "default:steel_ingot"},
                       {"default:diamond",    "default:steel_ingot",
                        "default:diamond"},
                       {"default:steel_ingot", "default:diamond",
                        "default:steel_ingot"}},
    },
}

-- ============================================================
-- Custom Punch Logic
-- ============================================================
local function on_punch(pos, node, puncher, pointed_thing)
    if not puncher or not puncher:is_player() then return end
    local pname = puncher:get_player_name()
    
    local tc = _G.rust_tc
    local is_auth = false
    local tc_data = nil
    
    if tc and tc.find_tc_at then
        local tc_id
        tc_id, tc_data = tc.find_tc_at(pos)
        if tc_data then
            is_auth = tc.can_access(pos, pname)
        else
            is_auth = true -- Немає TC, ламати можна всім
        end
    else
        is_auth = true
    end

    local tier = rust_building.tier_of(node.name)
    if not tier then return end
    
    local max_hp = rust_building.get_max_hp(tier)
    local damage_per_hit

    if is_auth then
        -- Власник або авторизований: 3 удари
        damage_per_hit = math.ceil(max_hp / 3)
    else
        -- Рейдер (не авторизований)
        -- Перевіряємо, чи гниє база (decay_pending > 0)
        local is_decaying = false
        if tc_data and tc_data.decay_pending and tc_data.decay_pending > 0 then
            is_decaying = true
        end

        if not is_decaying then
            -- База має ресурси (не гниє). Ламати руками НЕ МОЖНА.
            minetest.chat_send_player(pname, S("[Rust Survival] Not authorized to break a healthy block. Use explosives!"))
            return
        else
            -- База гниє! Дозволяємо рейдеру ламати (150 ударів)
            damage_per_hit = math.ceil(max_hp / 150)
        end
    end
    
    local result = rust_building.damage_node(pos, damage_per_hit, "punch")
    
    if result == "destroyed" then
        minetest.sound_play("default_dig_cracky", {pos = pos, gain = 1.0}, true)
        minetest.add_particlespawner({
            amount = 10, time = 0.2, minpos = pos, maxpos = pos,
            minvel = {x=-1, y=1, z=-1}, maxvel = {x=1, y=3, z=1},
            minacc = {x=0, y=-9, z=0}, maxacc = {x=0, y=-9, z=0},
            texture = "default_stone.png", 
        })
    else
        minetest.sound_play("default_dig_cracky", {pos = pos, gain = 0.5}, true)
        minetest.add_particlespawner({
            amount = 4, time = 0.1, minpos = pos, maxpos = pos,
            minvel = {x=-0.5, y=0.5, z=-0.5}, maxvel = {x=0.5, y=2, z=0.5},
            minacc = {x=0, y=-9, z=0}, maxacc = {x=0, y=-9, z=0},
            texture = "default_stone.png", 
        })
    end
end

local function make_on_construct(tier)
    return function(pos)
        local meta = get_meta(pos)
        if meta:get_int("rust_hp") == 0 then
            meta:set_int("rust_hp", rust_building.get_max_hp(tier))
        end
        meta:set_int("wipe_gen", rust_core.get_wipe_gen())
    end
end

local function on_destruct(pos)
    if rust_building._clear_cache then
        rust_building._clear_cache(pos)
    end

    -- Зменшуємо лічильник блоків у TC, якщо блок зник
    local tc = _G.rust_tc
    if tc and tc.find_tc_at then
        local tc_id, tc_data = tc.find_tc_at(pos)
        if tc_id and tc_data then
            tc_data.block_count = math.max(0, (tc_data.block_count or 0) - 1)
            tc.save(tc_id, tc_data)
            rust_core.log("action", "Block removed. TC #" .. tc_id .. " now has " .. tc_data.block_count .. " blocks.")
        end
    end
end

for tier, def in pairs(TIERS) do
    local name = "rust_building:" .. tier

    register_node(name, {
        description = def.description,
        tiles       = def.tiles,
        is_ground_content = false,
        diggable    = false,
        walkable    = true,
        groups = {
            rust_building = 1,
            ["rust_tier_" .. tier] = 1,
        },
        on_construct = make_on_construct(tier),
        on_destruct  = on_destruct,
        on_punch     = on_punch,
    })

    if def.craft then
        minetest.register_craft({
            output = name,
            recipe = def.craft,
        })
    end

    rust_building.DROPS = rust_building.DROPS or {}
    rust_building.DROPS[name] = def.drop
end

function rust_building.is_building(name)
    return minetest.get_item_group(name, "rust_building") > 0
end

function rust_building.tier_of(name)
    if not rust_building.is_building(name) then return nil end
    local def = minetest.registered_nodes[name]
    if not def or not def.groups then return nil end
    for tier in pairs(TIERS) do
        if (def.groups["rust_tier_" .. tier] or 0) > 0 then
            return tier
        end
    end
    return nil
end

rust_building.TIER_NAMES = {}
for tier in pairs(TIERS) do
    rust_building.TIER_NAMES[#rust_building.TIER_NAMES + 1] = tier
end

rust_core.log("action", "Registered " .. #rust_building.TIER_NAMES ..
    " building tiers (auth fast, raiders only on damaged blocks)")