-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_wipe/cleanup.lua
-- Lazy Wipe: видаляє блоки старої ери при завантаженні чанку.

local get_meta = minetest.get_meta
local remove_node = minetest.remove_node

minetest.register_lbm({
    name = "rust_wipe:lazy_cleanup",
    nodenames = {"group:rust_building", "rust_tc:cupboard"},
    run_at_every_load = true,
    action = function(pos, node)
        local meta = get_meta(pos)
        local block_gen = meta:get_int("wipe_gen")
        local current_gen = rust_core.get_wipe_gen()

        -- Видаляємо, якщо покоління блоку менше за поточне.
        -- (Блоки, поставлені до вайпу, матимуть 0, що теж менше за поточне)
        if block_gen < current_gen then
            remove_node(pos)
            
            -- Якщо це був TC, видаляємо його з бази (хоча база вже очищена)
            local tc_id = meta:get_int("tc_id")
            if tc_id > 0 and rust_tc.tcs[tc_id] then
                rust_tc.delete(tc_id)
            end
        end
    end,
})

rust_core.log("action", "Lazy wipe LBM registered")