-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/commands.lua

local S = minetest.get_translator("rust_tc")

local function msg(name, text)
    minetest.chat_send_player(name, text)
end

local function owner_check(name, tc, tc_id)
    if tc.owner ~= name then
        msg(name, S("[Rust Survival] Only the TC owner can do that"))
        return false
    end
    return true
end

-- ============================================================
-- /rust_tc_auth <player>
-- ============================================================
minetest.register_chatcommand("rust_tc_auth", {
    params = S("<player>"),
    description = S("Authorize a player for the TC you're in/near"),
    privs = {interact = true},
    func = function(name, param)
        param = param:trim()
        if param == "" then
            return false, S("Usage: /rust_tc_auth <player>")
        end

        local tc_id, tc = rust_tc.find_for_player(name)
        if not tc_id then
            return false, S("You are not near/in a TC")
        end
        if not owner_check(name, tc, tc_id) then return false end

        if not tc.authorized then tc.authorized = {} end
        if tc.authorized[param] then
            return true, S("Player '@1' is already authorized", param)
        end

        tc.authorized[param] = true
        rust_tc.save(tc_id, tc)
        return true, S("Authorized '@1' for TC #@2", param, tc_id)
    end,
})

-- ============================================================
-- /rust_tc_unauth <player>
-- ============================================================
minetest.register_chatcommand("rust_tc_unauth", {
    params = S("<player>"),
    description = S("Remove a player's authorization"),
    privs = {interact = true},
    func = function(name, param)
        param = param:trim()
        if param == "" then
            return false, S("Usage: /rust_tc_unauth <player>")
        end

        local tc_id, tc = rust_tc.find_for_player(name)
        if not tc_id then
            return false, S("You are not near/in a TC")
        end
        if not owner_check(name, tc, tc_id) then return false end

        if not tc.authorized or not tc.authorized[param] then
            return false, S("Player '@1' is not authorized", param)
        end

        tc.authorized[param] = nil
        rust_tc.save(tc_id, tc)
        return true, S("Removed '@1' from TC #@2", param, tc_id)
    end,
})

-- ============================================================
-- /rust_tc_info
-- ============================================================
minetest.register_chatcommand("rust_tc_info", {
    description = S("Info about the TC you're in/near"),
    privs = {interact = true},
    func = function(name)
        local tc_id, tc = rust_tc.find_for_player(name)
        if not tc_id then
            return false, S("You are not near/in a TC")
        end

        local auth_list = {}
        for n in pairs(tc.authorized or {}) do auth_list[#auth_list+1] = n end
        table.sort(auth_list)

        local hp = minetest.get_meta(tc.pos):get_int("rust_hp")

        msg(name, S("=== TC #@1 ===", tc_id))
        msg(name, S("Owner: @1", tc.owner))
        msg(name, S("Position: @1", minetest.pos_to_string(tc.pos)))
        msg(name, S("Radius: @1", tc.radius))
        msg(name, S("HP: @1 / @2", hp, (tonumber(minetest.settings:get("rust_tc_hp")) or 5000)))
        msg(name, S("Authorized: @1",
            (#auth_list > 0 and table.concat(auth_list, ", ") or S("(none)"))))
        msg(name, S("Created: @1", os.date("!%Y-%m-%d %H:%M UTC", tc.created_at or 0)))
        return true
    end,
})

-- ============================================================
-- /rust_tc_list
-- ============================================================
minetest.register_chatcommand("rust_tc_list", {
    description = S("List all TCs you own"),
    privs = {interact = true},
    func = function(name)
        local owned = {}
        for id, tc in pairs(rust_tc.tcs) do
            if tc.owner == name then
                owned[#owned+1] = {id = id, tc = tc}
            end
        end
        table.sort(owned, function(a, b) return a.id < b.id end)

        if #owned == 0 then
            return true, S("You own no TCs")
        end
        msg(name, S("Your TCs (@1):", #owned))
        for _, e in ipairs(owned) do
            msg(name, S("  #@1 at @2 (radius @3)", e.id, minetest.pos_to_string(e.tc.pos), e.tc.radius))
        end
        return true
    end,
})

-- ============================================================
-- /rust_tc_admin <action> [args]
-- ============================================================
minetest.register_chatcommand("rust_tc_admin", {
    params = S("<list|info|delete> [id]"),
    description = S("Admin: manage all TCs"),
    privs = {server = true},
    func = function(name, param)
        local action, arg = param:match("^(%S+)%s*(%S*)$")
        if not action then
            return false, S("Usage: /rust_tc_admin <list|info|delete> [id]")
        end

        if action == "list" then
            local count = 0
            for id, tc in pairs(rust_tc.tcs) do
                msg(name, S("  #@1 owner=@2 pos=@3 r=@4", id, tc.owner, minetest.pos_to_string(tc.pos), tc.radius))
                count = count + 1
            end
            return true, S("Total: @1 TCs", count)
        elseif action == "info" then
            local id = tonumber(arg)
            if not id or not rust_tc.tcs[id] then
                return false, S("TC #@1 not found", tostring(arg))
            end
            local tc = rust_tc.tcs[id]
            msg(name, minetest.write_json(tc))
            return true
        elseif action == "delete" then
            local id = tonumber(arg)
            if not id or not rust_tc.tcs[id] then
                return false, S("TC #@1 not found", tostring(arg))
            end
            local tc = rust_tc.tcs[id]
            minetest.remove_node(tc.pos)
            return true, S("Deleted TC #@1", id)
        end

        return false, S("Unknown action: @1", action)
    end,
})

-- ============================================================
-- /rust_tc_debug_decay
-- ============================================================
minetest.register_chatcommand("rust_tc_debug_decay", {
    description = S("Trigger one decay tick on your current TC (admin)"),
    privs = {server = true},
    func = function(name)
        local tc_id, tc = rust_tc.find_for_player(name)
        if not tc_id then return false, S("No TC nearby") end
        
        -- Додаємо 1 годину боргу
        tc.decay_pending = (tc.decay_pending or 0) + 1
        
        -- Наносимо шкоду за ВСЮ накопичену шкоду (щоб було видно ефект)
        rust_tc.apply_decay(tc, tc.decay_pending)
        
        -- Перевіряємо, чи не час знищити сам TC
        if tc.decay_pending >= 72 then
            minetest.chat_send_player(name, "TC destroyed by decay (72h limit)!")
            minetest.remove_node(tc.pos)
            rust_tc.delete(tc_id)
            return true
        end
        
        rust_tc.save(tc_id, tc)
        return true, S("Applied decay to TC #@1 (Decay pending: @2)", tc_id, tc.decay_pending)
    end,
})

-- ============================================================
-- /rust_tc_debug_tick
-- ============================================================
minetest.register_chatcommand("rust_tc_debug_tick", {
    description = S("Force-process one hour of upkeep on your current TC"),
    privs = {server = true},
    func = function(name)
        local tc_id, tc = rust_tc.find_for_player(name)
        if not tc_id then return false, S("No TC nearby") end
        tc.last_tick = tc.last_tick - 3600
        rust_tc.process_ticks(tc_id, tc)
        return true, S("Processed 1 tick on TC #@1 (pool now @2)", tc_id, tc.upkeep_pool or 0)
    end,
})