-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_building/init.lua
-- Tiered building blocks with HP stored in node metadata.
-- Only rust_raid.explode() may legitimately destroy these blocks.
-- All other destruction is audited and reverted (see audit.lua).

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

rust_building = {}
rust_building.MODNAME = modname

dofile(modpath .. "/blocks.lua")
dofile(modpath .. "/damage.lua")
dofile(modpath .. "/audit.lua")
--dofile(modpath .. "/debug.lua")

rust_core.log("action", "rust_building initialized")