-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/api.lua
-- Public API for downstream Rust Survival mods.
-- Time helpers respect rust_core.config.use_real_time.

local S = minetest.get_translator("rust_core")

local get_timeofday = minetest.get_timeofday
local get_gametime  = minetest.get_gametime
local os_date       = os.date
local os_time       = os.time

-- ============================================================
-- Tags
-- ============================================================
local tags = {}

function rust_core.register_tag(name, description)
    if tags[name] then
        rust_core.warn("Tag '" .. name .. "' already registered")
        return false
    end
    tags[name] = { description = description or name }
    return true
end

function rust_core.get_tag(name)
    return tags[name]
end

function rust_core.has_tag(itemstack, tag)
    if not itemstack or itemstack:is_empty() then return false end
    local def = minetest.registered_items[itemstack:get_name()]
    if not def or not def.groups then return false end
    return (def.groups["rust_tag_" .. tag] or 0) > 0
end

-- ============================================================
-- Time helpers
-- ============================================================
function rust_core.get_hour()
    if rust_core.config.use_real_time then
        local t = os_date("!*t")
        local h = t.hour + t.min / 60 + rust_core.config.utc_offset
        h = h % 24
        if h < 0 then h = h + 24 end
        return h
    end
    return get_timeofday() * 24
end

function rust_core.get_day()
    if rust_core.config.use_real_time then
        local ws = rust_core.db.get_int("world_start_utc", 0)
        if ws == 0 then return 1 end
        return math.floor((os_time() - ws) / 86400) + 1
    end
    return math.floor(get_gametime() / 1440) + 1
end

function rust_core.get_time_mode()
    return rust_core.config.use_real_time and "real" or "in-game"
end

function rust_core.get_world_start_utc()
    return rust_core.db.get_int("world_start_utc", 0)
end

-- ============================================================
-- Privileges
-- ============================================================
minetest.register_privilege("protection_bypass", {
    description = S("Bypass Rust Survival TC protection (moderators only)"),
    give_to_singleplayer = false,
})

rust_core.log("action", "API ready (priv: protection_bypass)")