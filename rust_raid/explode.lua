-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_raid/explode.lua
-- Core explosion API.

local S = minetest.get_translator("rust_raid")
local is_raid_window  = rust_hardcore.is_raid_window
local damage_node     = rust_building.damage_node

local get_node        = minetest.get_node
local get_meta        = minetest.get_meta
local remove_node     = minetest.remove_node
local add_item        = minetest.add_item
local get_connected_players = minetest.get_connected_players
local sound_play            = minetest.sound_play
local pos_to_string         = minetest.pos_to_string
local vector_distance       = vector.distance
local vector_direction      = vector.direction
local chat_send             = minetest.chat_send_player
local settings              = minetest.settings

local SOUND_NAME = settings:get("rust_raid_sound_name") or "rust_raid_explode"
local SOUND_GAIN = tonumber(settings:get("rust_raid_sound_gain")) or 2.0
local SOUND_DIST = tonumber(settings:get("rust_raid_sound_radius")) or 128

local PLAYER_DMG_MULT = tonumber(settings:get("rust_raid_player_damage_mult")) or 0.35
local KNOCKBACK_FORCE = tonumber(settings:get("rust_raid_knockback_force")) or 25.0

local function destroy_container(pos, node_name)
    local def = minetest.registered_nodes[node_name]
    local meta = get_meta(pos)
    local inv = meta:get_inventory()

    local drops = {}
    if inv then
        for _, list in pairs(inv:get_lists()) do
            for _, stack in ipairs(list) do
                if not stack:is_empty() then
                    drops[#drops + 1] = stack
                end
            end
        end
    end

    local drop_name = node_name
    if def and def.drop ~= nil then
        if def.drop == "" then
            drop_name = nil
        else
            drop_name = def.drop
        end
    end
    if drop_name then
        drops[#drops + 1] = drop_name
    end

    remove_node(pos)
    for _, item in ipairs(drops) do
        local stack = (type(item) == "string") and ItemStack(item) or item
        add_item({x = pos.x, y = pos.y, z = pos.z}, stack)
    end

    return #drops
end

local function damage_breakable(pos, amount, dtype)
    local node = get_node(pos)
    if not rust_raid.is_breakable(node.name) then
        return "not_breakable"
    end

    local meta = get_meta(pos)
    local hp = meta:get_int("rust_hp")
    if hp == 0 then
        hp = rust_raid.get_breakable_hp(node.name)
    end

    hp = hp - amount

    if hp <= 0 then
        local n = destroy_container(pos, node.name)
        rust_core.log("action", "Destroyed breakable " .. node.name ..
            " at " .. pos_to_string(pos) ..
            " (dtype=" .. tostring(dtype) ..
            ", dropped " .. n .. " items)")
        return "destroyed"
    end

    meta:set_int("rust_hp", hp)
    return "damaged"
end

local function do_explode(pos, radius, damage, dtype, source_name)
    local destroyed = 0
    local damaged = 0
    local r2 = radius * radius

    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local d2 = x*x + y*y + z*z
                if d2 <= r2 then
                    local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                    local dist = math.sqrt(d2)
                    local eff = math.max(0, dist - 1)
                    local falloff = 1 - eff / radius
                    local applied = math.floor(damage * falloff)
                    if applied > 0 then
                        local r_b = damage_node(p, applied, dtype)
                        local r_c = "not_breakable"
                        
                        if r_b == "no_block" then
                            r_c = damage_breakable(p, applied, dtype)
                        end

                        if r_b == "destroyed" or r_c == "destroyed" then
                            destroyed = destroyed + 1
                        elseif r_b == "damaged" or r_c == "damaged" then
                            damaged = damaged + 1
                        end
                    end
                end
            end
        end
    end

    for _, player in ipairs(get_connected_players()) do
        local ppos = player:get_pos()
        local dist = vector_distance(ppos, pos)
        if dist <= radius then
            local dmg = math.floor(damage * PLAYER_DMG_MULT * (1 - dist / radius))
            if dmg > 0 then
                player:set_hp(math.max(0, player:get_hp() - dmg), {type = "punch"})
            end

            if KNOCKBACK_FORCE > 0 and dist > 0.1 then
                local dir = vector_direction(pos, ppos)
                local force = KNOCKBACK_FORCE * (1 - dist / radius)
                
                player:set_pos({x = ppos.x, y = ppos.y + 0.2, z = ppos.z})

                local hor_force = force * 2.5 
                local ver_force = force * 0.5 + 2.5

                if player.add_velocity then
                    player:add_velocity({
                        x = dir.x * hor_force,
                        y = ver_force,
                        z = dir.z * hor_force
                    })
                else
                    local vel = player:get_velocity()
                    player:set_velocity({
                        x = vel.x + dir.x * hor_force,
                        y = math.max(vel.y, 0) + ver_force,
                        z = vel.z + dir.z * hor_force
                    })
                end

                local meta = player:get_meta()
                meta:set_int("rust_no_falldamage", 1)
                minetest.after(2.0, function()
                    if player and player:is_player() then
                        player:get_meta():set_int("rust_no_falldamage", 0)
                    end
                end)
            end
        end
    end

    sound_play(SOUND_NAME, {
        pos = pos,
        gain = SOUND_GAIN,
        max_hear_distance = SOUND_DIST, 
    })

    rust_core.log("action", string.format(
        "Explosion at %s (src=%s): %d destroyed, %d damaged (r=%d, dmg=%d)",
        pos_to_string(pos), tostring(source_name),
        destroyed, damaged, radius, damage))

    return destroyed, damaged
end

function rust_raid.explode(pos, radius, damage, dtype, source_name)
    if not is_raid_window() then
        rust_core.log("action", string.format(
            "Explosion BLOCKED at %s (raid window closed, src=%s)",
            pos_to_string(pos), tostring(source_name)))

        if source_name then
            chat_send(source_name, S("[Rust Survival] DUD — raid window closed."))
        end
        return false, "no_window"
    end

    local destroyed, damaged = do_explode(pos, radius, damage, dtype, source_name)
    if destroyed == 0 and damaged == 0 then
        return false, "no_blocks"
    end
    return true, nil
end