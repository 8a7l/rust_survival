-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/migrations.lua
-- Schema versioning + one-time world_start timestamp.
--
-- world_start_utc is the Unix timestamp (UTC) when this modpack
-- first ran on this world. Used by rust_core.get_day() in
-- real-time mode, and by the future wipe cycle (Stage 5).

local KEY_SCHEMA      = "schema_version"
local KEY_WORLD_START = "world_start_utc"
local TARGET = rust_core.SCHEMA_VERSION

local migrations = {}

local function apply_schema()
    local current = rust_core.db.get_int(KEY_SCHEMA)

    if current == TARGET then return end

    if current > TARGET then
        rust_core.warn("Schema on disk is v" .. current ..
            " but code expects v" .. TARGET ..
            ". Downgrade is not supported; leaving data untouched.")
        return
    end

    for v = current + 1, TARGET do
        local fn = migrations[v]
        if fn then
            rust_core.log("action", "Migrating schema v" ..
                (v - 1) .. " -> v" .. v)
            fn()
        end
    end

    rust_core.db.set_int(KEY_SCHEMA, TARGET)
    rust_core.log("action", "Schema at v" .. TARGET)
end

-- ============================================================
-- One-time: world start timestamp (for real-time day counter).
-- ============================================================
local function ensure_world_start()
    if rust_core.db.get_int(KEY_WORLD_START, 0) ~= 0 then return end
    local now = os.time()
    rust_core.db.set_int(KEY_WORLD_START, now)
    rust_core.log("action", "World start UTC: " .. now ..
        " (" .. os.date("!%Y-%m-%d %H:%M:%S", now) .. " UTC)")
end

apply_schema()
ensure_world_start()