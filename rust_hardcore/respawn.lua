-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/respawn.lua
-- Random respawn on death, Rust-style: you wake up far away
-- from where you died. No "home spawn", no safe zone.
--
-- Also exposes rust_hardcore.find_random_land() so that
-- join.lua (spawn rescue) can reuse the same logic.

local settings = minetest.settings
local ENABLED = settings:get_bool("rust_hardcore_respawn_random", true)
local RANGE = tonumber(settings:get("rust_hardcore_respawn_range")) or 1500

local get_spawn_level = minetest.get_spawn_level
local ATTEMPTS = 30

-- ============================================================
-- Try to find a random land position within RANGE blocks of origin.
-- Returns {x, y, z} or nil.
-- ============================================================
function rust_hardcore.find_random_land()
    if not get_spawn_level then
        return nil -- engine too old; caller will fall back
    end
    for _ = 1, ATTEMPTS do
        local x = math.random(-RANGE, RANGE)
        local z = math.random(-RANGE, RANGE)
        local y = get_spawn_level(x, z)
        if y and y > 0 then
            return {x = x, y = y + 1, z = z}
        end
    end
    return nil
end

-- ============================================================
-- Custom respawn. Return true = "we handled it" (no default).
-- Return false = let default engine respawn proceed.
-- ============================================================
local function on_respawn(player)
    if not ENABLED then return false end

    local pos = rust_hardcore.find_random_land()
    if not pos then
        rust_core.warn("Random respawn: no land found in " ..
            ATTEMPTS .. " attempts within " .. RANGE ..
            " blocks. Falling back to default respawn.")
        return false
    end

    player:set_pos(pos)
    rust_core.log("action", "Respawn: " ..
        player:get_player_name() .. " at " ..
        minetest.pos_to_string(pos))
    return true
end

minetest.register_on_respawnplayer(on_respawn)

rust_core.log("action", "Respawn handler registered (enabled=" ..
    tostring(ENABLED) .. ", range=" .. RANGE .. ")")