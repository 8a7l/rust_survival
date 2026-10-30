-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/config.lua
-- Centralised defaults. All Rust Survival mods read from here.

local settings = minetest.settings

rust_core.config = {
    log_level         = settings:get("rust_core_log_level") or "action",

    -- Time mode (global switch)
    use_real_time     = settings:get_bool("rust_core_use_real_time", false),
    utc_offset        = tonumber(settings:get("rust_core_utc_offset")) or 0,

    -- Wipe cycle
    wipe_cycle_days   = tonumber(settings:get("rust_core_wipe_cycle_days")) or 7,
    wipe_cycle_enabled = (settings:get("rust_core_wipe_cycle_days") or "7") ~= "0",
}

rust_core.log("action", "Config: time_mode=" ..
    (rust_core.config.use_real_time and "real (UTC" ..
        (rust_core.config.utc_offset >= 0 and "+" or "") ..
        rust_core.config.utc_offset .. ")" or "in-game") ..
    ", wipe_cycle=" .. (rust_core.config.wipe_cycle_enabled
        and (rust_core.config.wipe_cycle_days .. "d") or "off"))