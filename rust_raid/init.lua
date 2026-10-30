-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

rust_raid = {}

dofile(modpath .. "/gunpowder.lua")
dofile(modpath .. "/whitelist.lua")
dofile(modpath .. "/explode.lua")
dofile(modpath .. "/satchel.lua")
dofile(modpath .. "/c4.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/mines.lua")


rust_core.log("action", "rust_raid initialized (custom sound)")