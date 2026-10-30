-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/gunpowder.lua

local S = minetest.get_translator("rust_raid")

minetest.register_craftitem("rust_raid:gunpowder", {
    description = S("Gunpowder"),
    inventory_image = "default_coal_lump.png^[colorize:#888888:200",
    groups = {rust_material = 1},
})

minetest.register_craft({
    output = "rust_raid:gunpowder 2",
    recipe = {
        {"default:coal_lump", "default:sand"},
    },
})

rust_core.log("action", "Gunpowder registered")