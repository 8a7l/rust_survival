-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/death.lua
-- 100% death drop (Rust-style): all items spill onto the ground
-- at the place of death, inventory is cleared.
--
-- COMPATIBILITY NOTE (bones):
--   The default game includes a `bones` mod that also registers
--   on_dieplayer and puts items into a bones node.
--   To get pure Rust Survival behavior:
--     * either disable bones in world.mt (bones = false),
--     * or list rust_hardcore BEFORE bones in mods.conf.

local settings = minetest.settings
local ENABLED = settings:get_bool("rust_hardcore_death_drop", true)

local add_item = minetest.add_item

-- ============================================================
-- Drop one inventory slot to the ground with a small random offset
-- ============================================================
local function drop_stack(pos, stack)
    local offset = {
        x = pos.x + (math.random() - 0.5) * 1.5,
        y = pos.y + 0.5,
        z = pos.z + (math.random() - 0.5) * 1.5,
    }
    add_item(offset, stack)
end

-- ============================================================
-- Walk every list in the player inventory, drop non-empty slots,
-- then clear them in place.
-- ============================================================
local function spill_inventory(player, pos)
    local inv = player:get_inventory()
    if not inv then return 0 end

    local dropped = 0
    for listname, list in pairs(inv:get_lists()) do
        for i = 1, #list do
            local stack = list[i]
            if not stack:is_empty() then
                drop_stack(pos, stack)
                inv:set_stack(listname, i, ItemStack(""))
                dropped = dropped + 1
            end
        end
    end
    return dropped
end

-- ============================================================
-- Death handler
-- ============================================================
local function on_die(player)
    if not ENABLED then return end
    local pname = player:get_player_name()
    local pos = player:get_pos()
    if not pos then return end

    local n = spill_inventory(player, pos)
    rust_core.log("action", "Death drop: " .. pname ..
        " dropped " .. n .. " stack(s) at " ..
        minetest.pos_to_string(pos))
end

minetest.register_on_dieplayer(on_die)

-- ============================================================
-- Startup diagnostics
-- ============================================================
if minetest.get_modpath("bones") then
    rust_core.warn("'bones' mod detected. Death drops may conflict. " ..
        "Disable bones in world.mt, or list rust_hardcore above bones " ..
        "in mods.conf.")
end

rust_core.log("action", "Death handler registered (enabled=" ..
    tostring(ENABLED) .. ")")