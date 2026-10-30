-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/storage.lua
-- Per-TC JSON storage + Spatial Hash indexing.
-- FIX: TC is now indexed in ALL chunks its radius overlaps.

local settings = minetest.settings

local KEY_NEXT = "tc_next_id"
local KEY_PREFIX = "tc_"

rust_tc.PROTECT_ENABLED = settings:get_bool("rust_tc_protect_enabled", true)
rust_tc.tcs = {}
rust_tc.chunks = {} -- Spatial hash: chunk_key -> {id1, id2...}
rust_tc.next_id_counter = 1

-- ============================================================
-- Хеш чанку (16x16x16)
-- ============================================================
local CHUNK_SIZE = 16

local function pos_to_chunk_key(pos)
    local cx = math.floor(pos.x / CHUNK_SIZE)
    local cy = math.floor(pos.y / CHUNK_SIZE)
    local cz = math.floor(pos.z / CHUNK_SIZE)
    return cx .. ":" .. cy .. ":" .. cz
end

-- Додає ID у всі чанки, які покриває радіус TC
local function index_tc(id, tc)
    local r = tc.radius
    local minp = {x = tc.pos.x - r, y = tc.pos.y - r, z = tc.pos.z - r}
    local maxp = {x = tc.pos.x + r, y = tc.pos.y + r, z = tc.pos.z + r}
    
    local cx1 = math.floor(minp.x / CHUNK_SIZE)
    local cx2 = math.floor(maxp.x / CHUNK_SIZE)
    local cy1 = math.floor(minp.y / CHUNK_SIZE)
    local cy2 = math.floor(maxp.y / CHUNK_SIZE)
    local cz1 = math.floor(minp.z / CHUNK_SIZE)
    local cz2 = math.floor(maxp.z / CHUNK_SIZE)
    
    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            for cz = cz1, cz2 do
                local key = cx .. ":" .. cy .. ":" .. cz
                local list = rust_tc.chunks[key]
                if not list then
                    list = {}
                    rust_tc.chunks[key] = list
                end
                list[#list+1] = id
            end
        end
    end
end

-- Видаляє ID з усіх чанків
local function unindex_tc(id, tc)
    local r = tc.radius
    local minp = {x = tc.pos.x - r, y = tc.pos.y - r, z = tc.pos.z - r}
    local maxp = {x = tc.pos.x + r, y = tc.pos.y + r, z = tc.pos.z + r}
    
    local cx1 = math.floor(minp.x / CHUNK_SIZE)
    local cx2 = math.floor(maxp.x / CHUNK_SIZE)
    local cy1 = math.floor(minp.y / CHUNK_SIZE)
    local cy2 = math.floor(maxp.y / CHUNK_SIZE)
    local cz1 = math.floor(minp.z / CHUNK_SIZE)
    local cz2 = math.floor(maxp.z / CHUNK_SIZE)
    
    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            for cz = cz1, cz2 do
                local key = cx .. ":" .. cy .. ":" .. cz
                local list = rust_tc.chunks[key]
                if list then
                    for i = #list, 1, -1 do
                        if list[i] == id then
                            table.remove(list, i)
                            break
                        end
                    end
                    if #list == 0 then
                        rust_tc.chunks[key] = nil
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Load all TCs
-- ============================================================
local function load_all()
    local next_stored = rust_core.db.get_int(KEY_NEXT, 0)
    local max_id = 0
    local count = 0
    local migrated = 0

    for id = 1, next_stored do
        local raw = rust_core.db.get_string(KEY_PREFIX .. id, "")
        if raw ~= "" then
            local data = minetest.parse_json(raw)
            if data and data.owner and data.pos then
                if data.upkeep_pool == nil then
                    data.upkeep_pool = 0
                    migrated = migrated + 1
                end
                if data.last_tick == nil then
                    data.last_tick = os.time()
                end
                if data.decay_pending == nil then
                    data.decay_pending = 0
                end
                rust_tc.tcs[id] = data
                index_tc(id, data)
                if id > max_id then max_id = id end
                count = count + 1
            end
        end
    end

    rust_tc.next_id_counter = math.max(next_stored, max_id + 1)
    rust_core.log("action", "Loaded " .. count .. " TCs (next_id=" ..
        rust_tc.next_id_counter .. ")")
end

-- ============================================================
-- Public API
-- ============================================================
function rust_tc.save(id, data)
    local old_tc = rust_tc.tcs[id]
    if old_tc then
        unindex_tc(id, old_tc)
    end
    rust_tc.tcs[id] = data
    index_tc(id, data)
    rust_core.db.set_string(KEY_PREFIX .. id, minetest.write_json(data))
end

function rust_tc.delete(id)
    local tc = rust_tc.tcs[id]
    if tc then
        unindex_tc(id, tc)
    end
    rust_tc.tcs[id] = nil
    rust_core.db.set_string(KEY_PREFIX .. id, "")
end

function rust_tc.next_id()
    local id = rust_tc.next_id_counter
    rust_tc.next_id_counter = id + 1
    rust_core.db.set_int(KEY_NEXT, rust_tc.next_id_counter)
    return id
end

-- ============================================================
-- FAST LOOKUP (O(1))
-- ============================================================
function rust_tc.find_tc_at(pos)
    local key = pos_to_chunk_key(pos)
    local list = rust_tc.chunks[key]
    if not list then return nil end

    for _, id in ipairs(list) do
        local tc = rust_tc.tcs[id]
        if tc then
            local r = tc.radius
            if math.abs(pos.x - tc.pos.x) <= r
               and math.abs(pos.y - tc.pos.y) <= r
               and math.abs(pos.z - tc.pos.z) <= r then
                return id, tc
            end
        end
    end
    return nil
end

function rust_tc.can_access(pos, player_name)
    if not rust_tc.PROTECT_ENABLED then return true end
    if not player_name then return true end

    local id, tc = rust_tc.find_tc_at(pos)
    if not id then return true end
    
    if tc.owner == player_name then return true end
    if tc.authorized and tc.authorized[player_name] then return true end

    -- Захист скринь та дверей працює завжди, поки TC стоїть
    return false
end

load_all()