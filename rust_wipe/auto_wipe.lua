-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_wipe/auto_wipe.lua
-- Автоматичний вайп за таймером.

local S = minetest.get_translator("rust_wipe")
local settings = minetest.settings

local ENABLED = settings:get_bool("rust_wipe_auto_enabled", false)
local DAYS    = tonumber(settings:get("rust_wipe_auto_days")) or 7
local HARD    = settings:get_bool("rust_wipe_auto_hard", true)

local function check_wipe()
    if not ENABLED then return end

    local last_wipe = rust_core.db.get_int("last_wipe_time", 0)
    local now = os.time()

    -- Якщо вайпу ще ніколи не було, просто запам'ятовуємо поточний час
    if last_wipe == 0 then
        rust_core.db.set_int("last_wipe_time", now)
        return
    end

    local elapsed_days = (now - last_wipe) / 86400

    if elapsed_days >= DAYS then
        rust_core.log("action", "AUTO-WIPE triggered (" .. DAYS .. " days elapsed)")
        
        -- 1. Робимо софт-вайп (бази, TC, інвентарі онлайн-гравців)
        rust_wipe.do_wipe("AUTO-TIMER")

        -- 2. Якщо увімкнено HARD wipe, створюємо файл-маркер для .bat скрипта
        if HARD then
            local path = minetest.get_worldpath() .. "/WIPE_MAP.txt"
            local file = io.open(path, "w")
            if file then
                file:write("1")
                file:close()
                minetest.chat_send_all(S("[Rust Survival] !!! AUTO-WIPE !!!"))
                minetest.chat_send_all(S("[Rust Survival] Restart the server to generate a new map."))
            else
                rust_core.warn("Failed to create WIPE_MAP.txt for auto-wipe.")
            end
        end
    end
end

-- Перевіряємо при старті сервера (через 10 секунд після завантаження)
minetest.after(10, check_wipe)

-- Перевіряємо кожну годину
local function timer_loop()
    check_wipe()
    minetest.after(3600, timer_loop)
end
minetest.after(3600, timer_loop)

if ENABLED then
    rust_core.log("action", "Auto-wipe ENABLED (every " .. DAYS .. " days, hard=" .. tostring(HARD) .. ")")
else
    rust_core.log("action", "Auto-wipe DISABLED")
end