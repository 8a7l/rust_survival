-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/db.lua
-- Thin wrapper around mod_storage.
-- mod_storage is a key/value store backed by SQLite by default.
-- We do NOT expose raw SQL (Luanti doesn't). All values are
-- strings/ints/floats. Complex data (like TC radius) is JSON-encoded
-- in downstream mods, not here.
--
-- Why a wrapper: to have ONE place where schema keys are defined,
-- and to keep the door open for future sharding (Stage 4) without
-- touching every call site.

local storage = minetest.get_mod_storage()
rust_core.db = {}

-- String -----------------------------------------------------
function rust_core.db.get_string(key, default)
    local v = storage:get_string(key)
    if v == "" and default ~= nil then return default end
    return v
end
function rust_core.db.set_string(key, value)
    storage:set_string(key, value)
end

-- Integer ----------------------------------------------------
function rust_core.db.get_int(key, default)
    local v = storage:get_int(key)
    if v == 0 and default ~= nil then return default end
    return v
end
function rust_core.db.set_int(key, value)
    storage:set_int(key, value)
end

-- Float ------------------------------------------------------
function rust_core.db.get_float(key, default)
    local v = storage:get_float(key)
    if v == 0 and default ~= nil then return default end
    return v
end
function rust_core.db.set_float(key, value)
    storage:set_float(key, value)
end
-- ============================================================
-- Wipe Generation (для Stage 5)
-- ============================================================
local KEY_WIPE_GEN = "wipe_generation"

function rust_core.get_wipe_gen()
    return rust_core.db.get_int(KEY_WIPE_GEN, 1)
end

function rust_core.increment_wipe_gen()
    local gen = rust_core.get_wipe_gen() + 1
    rust_core.db.set_int(KEY_WIPE_GEN, gen)
    return gen
end