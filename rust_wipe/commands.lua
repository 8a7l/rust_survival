-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_wipe/commands.lua

local S = minetest.get_translator("rust_wipe")

minetest.register_chatcommand("rust_wipe", {
    description = S("Force a full server wipe (admin only)"),
    privs = {server = true},
    func = function(name, param)
        if param ~= "confirm" then
            return false, S("THIS WILL DESTROY ALL BASES! Type /rust_wipe confirm to confirm.")
        end
        rust_wipe.do_wipe(name)
        return true, S("Wipe started.")
    end,
})

minetest.register_chatcommand("rust_wipe_status", {
    description = S("Show auto-wipe status"),
    privs = {server = true},
    func = function(name)
        local settings = minetest.settings
        local enabled = settings:get_bool("rust_wipe_auto_enabled", false)
        local days = tonumber(settings:get("rust_wipe_auto_days")) or 7
        
        if not enabled then
            return true, S("Auto-wipe is DISABLED.")
        end

        local last_wipe = rust_core.db.get_int("last_wipe_time", 0)
        local now = os.time()
        local elapsed = (now - last_wipe) / 86400
        local left = days - elapsed
        
        if left <= 0 then
            return true, S("Auto-wipe is PENDING (will trigger on next check).")
        end
        
        return true, S("Auto-wipe ENABLED. Next wipe in @1 days.", string.format("%.1f", left))
    end,
})