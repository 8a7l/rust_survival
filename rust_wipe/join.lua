-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_wipe/join.lua
-- Очищення інвентаря та телепортація гравців, які пропустили вайп.

local S = minetest.get_translator("rust_wipe")

local function clear_inventory(player)
    local inv = player:get_inventory()
    if not inv then return end
    for listname, list in pairs(inv:get_lists()) do
        for i = 1, #list do
            inv:set_stack(listname, i, ItemStack(""))
        end
    end
end

-- Телепортація з подвійним підтвердженням
local function teleport_to_random_land(player)
    minetest.after(1.5, function()
        if not player or not player:is_player() then return end
        
        local new_pos = rust_hardcore.find_random_land()
        if new_pos then
            -- Трохи піднімаємо над землею, щоб уникнути застрягання
            new_pos.y = new_pos.y + 0.5 
            
            -- Перша спроба
            player:set_pos(new_pos)
            player:set_velocity({x=0, y=0, z=0})
            
            -- Друга спроба (через 0.5 секунди), щоб перебити позицію рушія
            minetest.after(0.5, function()
                if player and player:is_player() then
                    player:set_pos(new_pos)
                    player:set_velocity({x=0, y=0, z=0})
                end
            end)
            
            rust_core.log("action", "Wipe catch-up: teleported " .. player:get_player_name() .. " to " .. minetest.pos_to_string(new_pos))
        else
            rust_core.warn("Wipe catch-up: find_random_land returned nil for " .. player:get_player_name())
        end
    end)
end

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    local current_gen = rust_core.get_wipe_gen()
    local last_wipe_time = rust_core.db.get_int("last_wipe_time", 0)
    
    if last_wipe_time == 0 then return end

    local meta = player:get_meta()
    local last_gen = meta:get_int("rust_wipe_gen")
    local auth_handler = minetest.get_auth_handler()
    local auth = auth_handler and auth_handler.get_auth(pname)

    if last_gen == 0 then
        local creation_date = auth and auth.creation_date or 0
        if creation_date > last_wipe_time then
            meta:set_int("rust_wipe_gen", current_gen)
        else
            clear_inventory(player)
            teleport_to_random_land(player)
            meta:set_int("rust_wipe_gen", current_gen)
            minetest.chat_send_player(pname, S("[Rust Survival] Your inventory was cleared and you were moved due to a wipe."))
            rust_core.log("action", "Wipe catch-up (legacy): cleared " .. pname)
        end
    elseif last_gen < current_gen then
        clear_inventory(player)
        teleport_to_random_land(player)
        meta:set_int("rust_wipe_gen", current_gen)
        minetest.chat_send_player(pname, S("[Rust Survival] Your inventory was cleared and you were moved due to a wipe that occurred while you were offline."))
        rust_core.log("action", "Wipe catch-up: cleared " .. pname)
    end
end)

rust_core.log("action", "Wipe join-handler registered")