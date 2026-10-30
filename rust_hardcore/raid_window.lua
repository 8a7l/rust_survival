-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/raid_window.lua
-- Raid window = the time-of-day during which explosions work.

local S = minetest.get_translator("rust_hardcore")
local settings = minetest.settings

local ENABLED    = settings:get_bool("rust_hardcore_raid_window_enabled", true)
local START_HOUR = tonumber(settings:get("rust_hardcore_raid_window_start")) or 19
local END_HOUR   = tonumber(settings:get("rust_hardcore_raid_window_end"))   or 7

function rust_hardcore.is_raid_window()
    if not ENABLED then return true end
    local h = rust_core.get_hour()
    if START_HOUR <= END_HOUR then
        return h >= START_HOUR and h < END_HOUR
    else
        return h >= START_HOUR or h < END_HOUR
    end
end

function rust_hardcore.raid_window_status()
    if not ENABLED then return S("always open") end
    local h = rust_core.get_hour()
    local open = rust_hardcore.is_raid_window()
    local mode = (rust_core.get_time_mode() == "real") and S("real") or S("in-game")
    
    return string.format("%s (%s %02d:%02d, window %02d:00-%02d:00)",
        open and S("OPEN") or S("CLOSED"),
        mode,
        math.floor(h), math.floor((h % 1) * 60),
        START_HOUR, END_HOUR)
end

rust_core.log("action", "Raid window API ready (enabled=" ..
    tostring(ENABLED) .. ", time_mode=" .. rust_core.get_time_mode() .. ")")