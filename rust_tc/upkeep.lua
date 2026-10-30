-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/upkeep.lua
-- Math-based upkeep, decay, repair, and staggered queue.

local settings = minetest.settings
local ENABLED = settings:get_bool("rust_tc_upkeep_enabled", true)
local DECAY_PCT_PER_TICK = tonumber(settings:get("rust_tc_decay_pct")) or 0.04
local REPAIR_PCT_PER_TICK = tonumber(settings:get("rust_tc_repair_pct")) or 0.03
local MAX_TICKS_CATCHUP  = 168

rust_tc.FUEL_WEIGHTS = {
    ["default:wood"]        = 1,
    ["default:stone"]       = 2,
    ["rust_raid:gunpowder"] = 3,
    ["default:steel_ingot"] = 4,
    ["default:diamond"]     = 20,
}

function rust_tc.upkeep_cost(radius, block_count)
    local base_cost = math.max(1, math.floor(radius))
    local block_cost = math.floor((block_count or 0) / 5) 
    return base_cost + block_cost
end

function rust_tc.add_upkeep(pos, points)
    local meta = minetest.get_meta(pos)
    local tc_id = meta:get_int("tc_id")
    if tc_id == 0 then return false end
    local tc = rust_tc.tcs[tc_id]
    if not tc then return false end
    
    tc.upkeep_pool = (tc.upkeep_pool or 0) + points
    tc.decay_pending = 0 
    
    rust_tc.save(tc_id, tc)
    return true
end

-- ============================================================
-- Decay (Гниття з дропом)
-- ============================================================
function rust_tc.apply_decay(tc, ticks)
    if ticks <= 0 then return end
    if not minetest.get_node_or_nil(tc.pos) then return end

    local total_pct = DECAY_PCT_PER_TICK * ticks
    if total_pct > 1 then total_pct = 1 end

    local r = tc.radius
    local cx, cy, cz = tc.pos.x, tc.pos.y, tc.pos.z
    local destroyed = 0

    for x = cx - r, cx + r do
        for y = cy - r, cy + r do
            for z = cz - r, cz + r do
                local p = {x = x, y = y, z = z}
                local node = minetest.get_node(p)
                if minetest.get_item_group(node.name, "rust_building") > 0
                   and node.name ~= "rust_tc:cupboard" then
                    if rust_building.damage_node_pct(p, total_pct, "decay") == "destroyed" then
                        destroyed = destroyed + 1
                    end
                end
            end
        end
    end

    if destroyed > 0 then
        rust_core.log("action", "Decay: " .. destroyed .. " blocks decayed in TC")
    end
end

-- ============================================================
-- Repair (Ремонт)
-- ============================================================
function rust_tc.apply_repair(tc, ticks)
    local total_pct = REPAIR_PCT_PER_TICK * ticks
    if total_pct > 1 then total_pct = 1 end

    local r = tc.radius
    local cx, cy, cz = tc.pos.x, tc.pos.y, tc.pos.z
    local repaired = 0

    for x = cx - r, cx + r do
        for y = cy - r, cy + r do
            for z = cz - r, cz + r do
                local p = {x = x, y = y, z = z}
                local node = minetest.get_node(p)
                if minetest.get_item_group(node.name, "rust_building") > 0
                   and node.name ~= "rust_tc:cupboard" then
                    local tier = rust_building.tier_of(node.name)
                    if tier then
                        local max_hp = rust_building.get_max_hp(tier)
                        local heal_amt = math.ceil(max_hp * total_pct)
                        if rust_building.repair_node(p, heal_amt) == "repaired" then
                            repaired = repaired + 1
                        end
                    end
                end
            end
        end
    end

    if repaired > 0 then
        rust_core.log("action", "Repair: " .. repaired .. " blocks healed in TC")
    end
end

-- ============================================================
-- Обробка тіків
-- ============================================================
function rust_tc.process_ticks(id, tc)
    local now = os.time()
    local last = tc.last_tick or now
    local elapsed = now - last
    local ticks = math.min(math.floor(elapsed / 3600), MAX_TICKS_CATCHUP)
    
    if ticks < 1 then return end

    local cost = rust_tc.upkeep_cost(tc.radius, tc.block_count)
    local pool = tc.upkeep_pool or 0
    local total_cost = cost * ticks

    if pool >= total_cost then
        tc.upkeep_pool = pool - total_cost
        tc.decay_pending = 0
        rust_tc.apply_repair(tc, ticks)
    else
        local paid_ticks = math.floor(pool / cost)
        local unpaid_ticks = ticks - paid_ticks
        
        tc.upkeep_pool = pool - (paid_ticks * cost)
        tc.decay_pending = (tc.decay_pending or 0) + unpaid_ticks
        
        -- Наносимо шкоду
        rust_tc.apply_decay(tc, unpaid_ticks)
        
        -- Якщо борг перевищує 72 години (3 доби) - знищуємо сам TC
        if tc.decay_pending >= 72 then
            rust_core.log("action", "TC #" .. id .. " completely destroyed by decay!")
            minetest.remove_node(tc.pos)
            rust_tc.delete(id)
            return
        end
    end

    tc.last_tick = now - (elapsed % 3600)
    rust_tc.save(id, tc)
end

-- ============================================================
-- Staggered Queue
-- ============================================================
local queue = {}

local function build_queue()
    queue = {}
    for id in pairs(rust_tc.tcs) do
        table.insert(queue, id)
    end
end

local function process_batch()
    if not ENABLED then return end
    
    if #queue == 0 then
        build_queue()
        minetest.after(60, process_batch)
        return
    end

    local batch_size = 50
    for _ = 1, math.min(batch_size, #queue) do
        local id = table.remove(queue, 1)
        local tc = rust_tc.tcs[id]
        if tc then
            rust_tc.process_ticks(id, tc)
        end
    end

    minetest.after(0.2, process_batch)
end

minetest.after(5, process_batch)

rust_core.log("action", "Upkeep system ready (decay state preserved)")