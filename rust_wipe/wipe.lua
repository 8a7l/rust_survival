-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_wipe/wipe.lua
-- Головна логіка вайпу.

local S = minetest.get_translator("rust_wipe")
local get_connected_players = minetest.get_connected_players
local chat_send_all = minetest.chat_send_all

-- ============================================================
-- Очищення завантажених TC через VoxelManip (без лагів)
-- ============================================================
local function clear_loaded_bases()
    local get_vm = minetest.get_voxel_manip
    local c_air = minetest.get_content_id("air")
    local count = 0

    for id, tc in pairs(rust_tc.tcs) do
        local p = tc.pos
        if minetest.get_node_or_nil(p) then
            local r = tc.radius
            local minp = {x = p.x - r, y = p.y - r, z = p.z - r}
            local maxp = {x = p.x + r, y = p.y + r, z = p.z + r}
            
            local vm = get_vm()
            local emin, emax = vm:read_from_map(minp, maxp)
            local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
            local data = vm:get_data()
            local changed = false

            for x = minp.x, maxp.x do
                for y = minp.y, maxp.y do
                    for z = minp.z, maxp.z do
                        local idx = area:index(x, y, z)
                        local n_name = minetest.get_name_from_content_id(data[idx])
                        if minetest.get_item_group(n_name, "rust_building") > 0 then
                            data[idx] = c_air
                            changed = true
                        end
                    end
                end
            end
            if changed then
                vm:set_data(data)
                vm:write_to_map()
                count = count + 1
            end
        end
    end
    return count
end

-- ============================================================
-- Головна функція вайпу
-- ============================================================
function rust_wipe.do_wipe(admin_name)
    local new_gen = rust_core.increment_wipe_gen()
    
    -- 1. ЗБЕРІГАЄМО ЧАС ВАЙПУ (для сумісності)
    rust_core.db.set_int("last_wipe_time", os.time())

    -- 2. Миттєве очищення завантажених баз
    local cleared = clear_loaded_bases()

    -- 3. Очищення бази даних TC
    local tc_count = 0
    for id in pairs(rust_tc.tcs) do
        rust_tc.delete(id)
        tc_count = tc_count + 1
    end

    -- 4. Очищення інвентарів та телепортація ОНЛАЙН-гравців
    local cleaned_players = 0
    for _, player in ipairs(get_connected_players()) do
        local pname = player:get_player_name()
        local inv = player:get_inventory()
        
        if inv then
            for listname, list in pairs(inv:get_lists()) do
                for i = 1, #list do
                    inv:set_stack(listname, i, ItemStack(""))
                end
            end
            cleaned_players = cleaned_players + 1
        end

        -- Оновлюємо мітку покоління для гравця, щоб join.lua не чіпав його знову
        player:get_meta():set_int("rust_wipe_gen", new_gen)

        -- Телепортуємо на нове місце
        local pos = rust_hardcore.find_random_land()
        if pos then player:set_pos(pos) end
        minetest.chat_send_player(pname, S("[Rust Survival] Wipe! World reset. You start from scratch."))
    end

    -- 5. Сповіщення
    chat_send_all(S("[Rust Survival] === SERVER HAS BEEN WIPED (Era @1) ===", new_gen))
    chat_send_all(S("[Rust Survival] All bases destroyed. Online players cleared: @1", cleaned_players))
    
    rust_core.log("action", "WIPE completed by " .. tostring(admin_name) ..
        ": TC=" .. tc_count .. ", instant_clears=" .. cleared ..
        ", online_players_cleaned=" .. cleaned_players ..
        ", new_gen=" .. new_gen)
end