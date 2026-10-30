-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/commands.lua

local S = minetest.get_translator("rust_raid")

minetest.register_chatcommand("rust_raid_test", {
    params = S("<radius> <damage>"),
    description = S("Trigger a test explosion at your feet (admin)"),
    privs = {server = true},
    func = function(name, param)
        local radius, damage = param:match("^(%d+)%s+(%d+)$")
        radius = tonumber(radius)
        damage = tonumber(damage)
        if not radius or not damage then
            return false, S("Usage: /rust_raid_test <radius> <damage>")
        end

        local player = minetest.get_player_by_name(name)
        if not player then return false, S("Player not found") end

        local pos = player:get_pos()
        local p = {
            x = math.floor(pos.x),
            y = math.floor(pos.y) - 1,
            z = math.floor(pos.z),
        }

        local ok, err = rust_raid.explode(p, radius, damage, "debug", name)
        if not ok then
            return false, S("Explosion failed: @1", tostring(err))
        end
        return true, S("Boom.")
    end,
})

minetest.register_chatcommand("rust_raid_status", {
    description = S("Show raid window status"),
    func = function(name)
        minetest.chat_send_player(name,
            S("[Rust Survival] Raid: @1", rust_hardcore.raid_window_status()))
        return true
    end,
})

minetest.register_chatcommand("rust_raid_register_breakable", {
    params = S("<node> [hp]"),
    description = S("Register a node as breakable by explosions"),
    privs = {server = true},
    func = function(name, param)
        local node, hp = param:match("^(%S+)%s*(%d*)$")
        if not node then
            return false, S("Usage: /rust_raid_register_breakable <node> [hp]")
        end
        if not minetest.registered_nodes[node] then
            return false, S("Node '@1' not registered", node)
        end
        rust_raid.register_breakable(node, tonumber(hp) or 200)
        return true, S("Registered '@1' as breakable", node)
    end,
})

minetest.register_chatcommand("rust_raid_breakables", {
    description = S("List all registered breakable nodes"),
    privs = {server = true},
    func = function(name)
        local list = {}
        for n in pairs(rust_raid.BUILTIN_BREAKABLE) do
            list[#list+1] = n .. " (" .. S("builtin") .. ")"
        end
        for n in pairs(rust_raid.breakable) do
            list[#list+1] = n .. " (" .. S("custom") .. ")"
        end
        table.sort(list)
        minetest.chat_send_player(name,
            S("[Rust Survival] Breakables (@1): @2", #list, table.concat(list, ", ")))
        minetest.chat_send_player(name,
            S("[Rust Survival] Plus all doors/gates (checked at runtime)"))
        return true
    end,
})