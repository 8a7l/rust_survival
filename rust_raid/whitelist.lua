-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/whitelist.lua
-- Breakable container registry.
--
-- Doors and gates get MATERIAL-TIERED HP:
--   * steel / iron / metal in name  -> rust_building.MAX_HP.metal (1000)
--   * stone in name                 -> rust_building.MAX_HP.stone (500)
--   * wood / wooden / no hint       -> rust_building.MAX_HP.wood  (250)
--
-- Chests and furnaces keep a fixed HP (200) — they're not "doors",
-- they're storage, and should pop easily regardless of tier.

local settings = minetest.settings
local DEFAULT_HP = tonumber(settings:get("rust_raid_breakable_hp")) or 200

rust_raid.DEFAULT_BREAKABLE_HP = DEFAULT_HP

-- Builtin containers (fixed HP, not tier-based)
rust_raid.BUILTIN_BREAKABLE = {
    ["default:chest"]          = DEFAULT_HP,
    ["default:chest_locked"]   = DEFAULT_HP,
    ["default:furnace"]        = DEFAULT_HP,
    ["default:furnace_active"] = DEFAULT_HP,
}

-- Custom breakables registered via API
rust_raid.breakable = {}
rust_raid.breakable_hp = {}

-- ============================================================
-- Material tiers, checked in order (most specific first)
-- ============================================================
local MATERIAL_ORDER = {
    {"armored", "armored", 2000},
    {"steel",   "metal",   1000},
    {"iron",    "metal",   1000},
    {"metal",   "metal",   1000},
    {"stone",   "stone",    500},
    {"wooden",  "wood",     250},  -- must come before "wood"
    {"wood",    "wood",     250},
}

-- ============================================================
-- Caches (result by node name; invalidated on register_breakable)
-- ============================================================
local breakable_cache = {}
local hp_cache = {}

-- ============================================================
-- Public API
-- ============================================================
function rust_raid.register_breakable(name, hp)
    if type(name) ~= "string" then return false end
    rust_raid.breakable[name] = true
    rust_raid.breakable_hp[name] = tonumber(hp) or DEFAULT_HP
    breakable_cache[name] = nil
    hp_cache[name] = nil
    rust_core.log("action", "Registered breakable: " .. name ..
        " (hp=" .. rust_raid.breakable_hp[name] .. ")")
    return true
end

-- ============================================================
-- Internal helpers
-- ============================================================
local function hp_from_material(name)
    local lower = name:lower()
    for _, entry in ipairs(MATERIAL_ORDER) do
        local pattern, tier, fallback = entry[1], entry[2], entry[3]
        if lower:find(pattern, 1, true) then
            -- Prefer rust_building's configured HP (keeps tiers in sync)
            if rust_building and rust_building.MAX_HP
               and rust_building.MAX_HP[tier] then
                return rust_building.MAX_HP[tier]
            end
            return fallback
        end
    end
    return nil
end

local function is_door_like(name)
    return minetest.get_item_group(name, "door") > 0
        or minetest.get_item_group(name, "gate") > 0
end

-- ============================================================
-- is_breakable(name)
-- ============================================================
function rust_raid.is_breakable(name)
    local c = breakable_cache[name]
    if c ~= nil then return c end

    c = false
    if rust_raid.BUILTIN_BREAKABLE[name] then
        c = true
    elseif rust_raid.breakable[name] then
        c = true
    elseif is_door_like(name) then
        c = true
    end

    breakable_cache[name] = c
    return c
end

-- ============================================================
-- get_breakable_hp(name)
--
-- Resolution order:
--   1. Explicit HP (builtin or API-registered)
--   2. Material hint in name (steel/iron/metal/stone/wood)
--   3. Door-like without hint -> wood tier (most vanilla defaults)
--   4. Else -> DEFAULT_HP (200)
-- ============================================================
function rust_raid.get_breakable_hp(name)
    local c = hp_cache[name]
    if c then return c end

    local hp = rust_raid.BUILTIN_BREAKABLE[name]
        or rust_raid.breakable_hp[name]
        or hp_from_material(name)

    if not hp then
        if is_door_like(name) then
            hp = (rust_building and rust_building.MAX_HP
                  and rust_building.MAX_HP.wood) or 250
        else
            hp = DEFAULT_HP
        end
    end

    hp_cache[name] = hp
    return hp
end

-- ============================================================
-- Startup log: show resolved tiers for common vanilla nodes
-- ============================================================
local function log_tiers()
    local samples = {
        "doors:door_wood_a", "doors:door_steel_a",
        "doors:trapdoor",    "doors:trapdoor_steel",
        "default:chest",     "default:furnace",
    }
    for _, n in ipairs(samples) do
        if minetest.registered_nodes[n] then
            rust_core.log("action", "  " .. n ..
                " -> hp=" .. rust_raid.get_breakable_hp(n))
        end
    end
end

minetest.after(0, log_tiers)

rust_core.log("action", "Whitelist ready (default HP=" ..
    DEFAULT_HP .. ", doors use material tiers)")