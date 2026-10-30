-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_tc/formspec.lua

local S = minetest.get_translator("rust_tc")

local function show(pos, player)
    local meta = minetest.get_meta(pos)
    local tc_id = meta:get_int("tc_id")
    if tc_id == 0 then return end
    local tc = rust_tc.tcs[tc_id]
    if not tc then return end

    local pname = player:get_player_name()
    if tc.owner ~= pname
       and not (tc.authorized and tc.authorized[pname]) then
        minetest.chat_send_player(pname, S("[Rust Survival] You are not authorized for this TC"))
        return
    end

    local inv = meta:get_inventory()
    if inv:get_size("deposit") == 0 then
        inv:set_size("deposit", 1)
    end

    -- Передаємо кількість блоків для розрахунку!
    local cost = rust_tc.upkeep_cost(tc.radius, tc.block_count)
    local pool = tc.upkeep_pool or 0
    local hours = math.floor(pool / cost)
    
    local hours_str = S("EXPIRING!")
    if hours > 0 then
        hours_str = S("@1h", hours)
    elseif pool > 0 then
        hours_str = S("<1h")
    end

    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z

    local fs = "formspec_version[4]" ..
        "size[10.8,11.2]" ..
        "bgcolor[#1e1e1edd;false]" ..
        "listcolors[#333333;#999999;#FFFFFF;#444444;#FFFFFF]" ..

        "label[0.5,0.3;" .. S("Tool Cupboard #@1", tc_id) .. "]" ..
        "button_exit[9.3,0.2;1.2,0.6;close;" .. S("Close") .. "]" ..

        "label[0.5,1.2;" .. S("Owner: @1", tc.owner) .. "]" ..
        "label[0.5,1.8;" .. S("Radius: @1 blocks", tc.radius) .. "]" ..
        "label[0.5,2.4;" .. S("Upkeep: @1 pts/hour", cost) .. "]" ..
        "label[0.5,3.0;" .. S("Stored: @1 pts (@2)", pool, hours_str) .. "]" ..
        "label[0.5,3.6;" .. S("HP: @1", meta:get_int("rust_hp")) .. "]" ..

        "label[5.8,1.2;" .. S("Deposit Fuel:") .. "]" ..
        "box[5.8,1.6;1.2,1.2;#333333]" ..
        "list[nodemeta:" .. pos_str .. ";deposit;5.8,1.6;1,1;]" ..
        "label[7.2,1.9;" .. S("<- Drag here") .. "]" ..
        "label[5.8,3.2;" .. S("Wood=1 Stone=2") .. "]" ..
        "label[5.8,3.7;" .. S("Steel=4 Diam=20") .. "]" ..

        "label[0.5,4.3;" .. S("Your Inventory:") .. "]" ..
        "list[current_player;main;0.5,4.6;8,4;]" ..
        "list[current_player;hotbar;0.5,9.7;8,1;]" ..
        
        "listring[current_player;main]" ..
        "listring[nodemeta:" .. pos_str .. ";deposit]"

    minetest.show_formspec(pname, "rust_tc:main_" .. tc_id, fs)
end

rust_tc.show_formspec = show