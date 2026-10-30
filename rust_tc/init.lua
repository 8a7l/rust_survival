-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/init.lua

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

rust_tc = {}

dofile(modpath .. "/storage.lua")
dofile(modpath .. "/upkeep.lua")     -- BEFORE tc_node (upkeep_cost used there)
dofile(modpath .. "/formspec.lua")   -- BEFORE tc_node (show_formspec used there)
dofile(modpath .. "/tc_node.lua")
dofile(modpath .. "/protection.lua")
dofile(modpath .. "/commands.lua")

rust_core.log("action", "rust_tc initialized")