-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

rust_wipe = {}

dofile(modpath .. "/wipe.lua")
dofile(modpath .. "/cleanup.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/join.lua")
dofile(modpath .. "/auto_wipe.lua")

rust_core.log("action", "rust_wipe initialized")