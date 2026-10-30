-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/init.lua
-- Hardcore death, respawn, and raid window.
-- Stage 1 of RustCraft: playable hardcore without raiding yet.

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Direct assignment to avoid strict-mode warning.
rust_hardcore = {}

dofile(modpath .. "/respawn.lua")   -- loads first: exposes find_random_land
dofile(modpath .. "/death.lua")
dofile(modpath .. "/join.lua")
dofile(modpath .. "/raid_window.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/nametags.lua")
dofile(modpath .. "/player_hud.lua")


rust_core.log("action", "rust_hardcore initialized")