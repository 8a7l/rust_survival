-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/mines.lua
-- Міни-розтяжки (точне визначення наступання через AABB).

local S = minetest.get_translator("rust_raid")
local settings = minetest.settings

local MINE_DAMAGE = tonumber(settings:get("rust_raid_mine_damage")) or 300
local MINE_RADIUS = tonumber(settings:get("rust_raid_mine_radius")) or 2

local get_node = minetest.get_node
local remove_node = minetest.remove_node
local get_meta = minetest.get_meta
local chat_send = minetest.chat_send_player
local find_nodes = minetest.find_nodes_in_area

local TEX_ITEM = "rust_raid_mine.png"
local TEX_ARMED = "rust_raid_mine_armed.png"
local TEX_SIDE = "blank.png" 

minetest.register_node("rust_raid:mine_armed", {
    description = S("Armed Landmine"),
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.49, 0.5},
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
    },
    tiles = {TEX_ARMED, TEX_SIDE, TEX_SIDE, TEX_SIDE, TEX_SIDE, TEX_SIDE},
    use_texture_alpha = "blend", 
    is_ground_content = false,
    walkable = false,            
    pointable = true,
    diggable = true,
    drop = "rust_raid:mine",
    paramtype = "light",
    sunlight_propagates = true,
    groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
})

minetest.register_craftitem("rust_raid:mine", {
    description = S("Landmine (Explodes on step)"),
    inventory_image = TEX_ITEM,
    stack_max = 10,

    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        local pos = pointed_thing.above
        if get_node(pos).name ~= "air" then return itemstack end

        minetest.set_node(pos, {name = "rust_raid:mine_armed"})
        local meta = get_meta(pos)

        if user and user:is_player() then
            local pname = user:get_player_name()
            meta:set_string("placer", pname)
            chat_send(pname, S("[Rust Survival] Landmine armed."))
        end

        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_craft({
    output = "rust_raid:mine",
    recipe = {
        {"rust_raid:gunpowder", "default:steel_ingot", "rust_raid:gunpowder"},
        {"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
    },
})

local function is_friend_of_tc(pos, pname)
    local tc = _G.rust_tc
    if not tc or not tc.find_tc_at then return false end

    local tc_id, tc_data = tc.find_tc_at(pos)
    if not tc_id then return false end

    if tc_data.owner == pname then return true end
    if tc_data.authorized and tc_data.authorized[pname] then return true end
    return false
end

local timer = 0

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 0.1 then return end
    timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local pname = player:get_player_name()
        
        -- Перевіряємо область навколо гравця (його хітбокс)
        -- По X та Z беремо 0.4 блоку в кожен бік (щоб покрити краї)
        -- По Y перевіряємо від ніг (pos.y - 0.5) до голови (pos.y + 1.5)
        local p1 = {
            x = math.floor(pos.x - 0.4),
            y = math.floor(pos.y - 0.5),
            z = math.floor(pos.z - 0.4)
        }
        local p2 = {
            x = math.floor(pos.x + 0.4),
            y = math.floor(pos.y + 1.5),
            z = math.floor(pos.z + 0.4)
        }

        -- Знаходимо всі міни в цій області (це швидка функція C++)
        local mines = find_nodes(p1, p2, {"rust_raid:mine_armed"})

        for _, mine_pos in ipairs(mines) do
            local meta = get_meta(mine_pos)
            local placer = meta:get_string("placer")

            if pname ~= placer and not is_friend_of_tc(mine_pos, pname) then
                -- Перевіряємо, чи відкрито вікно рейдів
                if rust_hardcore.is_raid_window() then
                    remove_node(mine_pos)
                    rust_raid.explode(mine_pos, MINE_RADIUS, MINE_DAMAGE, "landmine", nil)
                end
                -- Якщо вікно закрито, міна залишається на місці, нічого не відбувається
                break -- Якщо знайшли одну міну, далі не перевіряємо
            end
        end
    end
end)

rust_core.log("action", "Landmines registered (AABB precise hitbox)")