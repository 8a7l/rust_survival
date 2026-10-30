-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/commands.lua
-- Admin diagnostic command.

local S = minetest.get_translator("rust_hardcore")

local function msg(name, text)
    minetest.chat_send_player(name, text)
end

minetest.register_chatcommand("rust_hardcore_info", {
    description = S("Show Rust Survival hardcore status"),
    privs = {server = true},
    func = function(name)
        local mode = rust_core.get_time_mode()
        local h = rust_core.get_hour()
        
        -- Перекладаємо режим часу для гравця
        local mode_str = (mode == "real") and S("real") or S("in-game")

        msg(name, S("=== rust_hardcore ==="))
        msg(name, S("Time mode: @1", mode_str))
        msg(name, S("Hour: @1", string.format("%02d:%02d",
            math.floor(h), math.floor((h % 1) * 60))))
        msg(name, S("Day: @1", rust_core.get_day()))
        msg(name, S("Raid window: @1", rust_hardcore.raid_window_status()))
        
        local wipe_str = rust_core.config.wipe_cycle_enabled
            and S("@1 @2 days", rust_core.config.wipe_cycle_days, mode_str)
            or S("disabled")
        msg(name, S("Wipe cycle: @1", wipe_str))
        
        return true
    end,
})