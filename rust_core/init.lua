-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/init.lua
-- Foundation for the RustCraft modpack.
-- Provides logging, config, schema versioning, and public API
-- that downstream mods (rust_hardcore, rust_raid, ...) use.
-- No gameplay here, only infrastructure.

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Loaded first in the modpack, so no need to preserve existing value.
-- Direct assignment avoids strict-mode warning about reading an
-- undeclared global.
rust_core = {}
rust_core.MODNAME = modname
rust_core.MODPATH = modpath
rust_core.SCHEMA_VERSION = 1

dofile(modpath .. "/log.lua")
dofile(modpath .. "/config.lua")
dofile(modpath .. "/db.lua")
dofile(modpath .. "/migrations.lua")
dofile(modpath .. "/api.lua")

rust_core.log("action", "Initialized (schema v" ..
    rust_core.db.get_int("schema_version") .. ")")