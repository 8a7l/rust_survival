-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_building/damage.lua
-- Public damage API + HP storage.

local settings = minetest.settings
local get_meta = minetest.get_meta
local get_node = minetest.get_node
local remove_node = minetest.remove_node
local pos_to_string = minetest.pos_to_string
local add_item = minetest.add_item

local DEFAULTS = {
    wood    = 250,
    stone   = 1000,  -- Змінено з 500
    metal   = 2000,  -- Змінено з 1000
    armored = 4000,  -- Змінено з 2000
}

local MAX_HP = {}
for _, tier in ipairs(rust_building.TIER_NAMES) do
    local key = "rust_building_hp_" .. tier
    MAX_HP[tier] = tonumber(settings:get(key)) or DEFAULTS[tier]
end
rust_building.MAX_HP = MAX_HP

local hp_cache = {}

function rust_building.get_max_hp(tier)
    return MAX_HP[tier] or 0
end

function rust_building.get_hp(pos)
    local meta = get_meta(pos)
    local hp = meta:get_int("rust_hp")
    if hp > 0 then return hp end

    local node = get_node(pos)
    local tier = rust_building.tier_of(node.name)
    if not tier then return 0 end
    hp = MAX_HP[tier]
    meta:set_int("rust_hp", hp)
    return hp
end

local function destroy_node(pos, node)
    local drop = rust_building.DROPS[node.name]
    remove_node(pos)
    if drop then
        add_item(pos, drop)
    end
    hp_cache[pos_to_string(pos)] = nil
end

function rust_building.damage_node(pos, amount, dtype)
    local node = get_node(pos)
    local tier = rust_building.tier_of(node.name)
    if not tier then return "no_block" end

    local meta = get_meta(pos)
    local hp = meta:get_int("rust_hp")
    if hp == 0 then
        hp = MAX_HP[tier]
    end

    hp = hp - amount

    if hp <= 0 then
        destroy_node(pos, node)
        rust_core.log("action", "Destroyed " .. node.name ..
            " at " .. pos_to_string(pos) ..
            " (dtype=" .. tostring(dtype) .. ")")
        return "destroyed"
    end

    meta:set_int("rust_hp", hp)
    hp_cache[pos_to_string(pos)] = hp
    return "damaged"
end

function rust_building._cached_hp(pos)
    return hp_cache[pos_to_string(pos)]
end
-- ============================================================
-- Відновлення HP (використовується для ремонту TC)
-- ============================================================
function rust_building.repair_node(pos, amount)
    local node = get_node(pos)
    local tier = rust_building.tier_of(node.name)
    if not tier then return "no_block" end

    local meta = get_meta(pos)
    local hp = meta:get_int("rust_hp")
    local max_hp = MAX_HP[tier]

    if hp == 0 then hp = max_hp end
    if hp >= max_hp then return "full" end -- Вже цілий

    hp = math.min(max_hp, hp + amount)
    meta:set_int("rust_hp", hp)
    hp_cache[pos_to_string(pos)] = hp
    return "repaired"
end
-- Called from blocks.lua on_destruct to clean the cache on hand-dig.
function rust_building._clear_cache(pos)
    hp_cache[pos_to_string(pos)] = nil
end

minetest.register_on_shutdown(function()
    hp_cache = {}
end)

rust_core.log("action", "Damage API ready (hp values: " ..
    "wood=" .. MAX_HP.wood .. ", " ..
    "stone=" .. MAX_HP.stone .. ", " ..
    "metal=" .. MAX_HP.metal .. ", " ..
    "armored=" .. MAX_HP.armored .. ")")
	
-- ============================================================
-- Percentage-based damage (used by rust_tc decay)
-- ============================================================
function rust_building.damage_node_pct(pos, pct, dtype)
    local node = get_node(pos)
    local tier = rust_building.tier_of(node.name)
    if not tier then return "no_block" end

    local meta = get_meta(pos)
    local hp = meta:get_int("rust_hp")
    if hp == 0 then hp = MAX_HP[tier] end

    local dmg = math.ceil(hp * pct)
    if dmg < 1 then dmg = 1 end

    return rust_building.damage_node(pos, dmg, dtype)
end