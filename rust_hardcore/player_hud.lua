-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/player_hud.lua
-- Показує найближчих гравців у правому верхньому куті екрана.

local hud_ids = {}
local timer = 0

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    hud_ids[pname] = player:hud_add({
        type          = "text",              -- ВИПРАВЛЕНО: type замість hud_elem_type
        position      = {x = 1, y = 0},      
        offset        = {x = -20, y = 20},   
        alignment     = {x = -1, y = 1},     
        text          = "",
        scale         = {x = 100, y = 100},
        number        = 0xFFFFFF,            
    })
end)

minetest.register_on_leaveplayer(function(player)
    hud_ids[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 0.5 then return end 
    timer = 0

    local players = minetest.get_connected_players()
    
    for _, player in ipairs(players) do
        local pname = player:get_player_name()
        local pos = player:get_pos()
        local nearby = {}

        for _, other in ipairs(players) do
            if other ~= player then
                local opos = other:get_pos()
                local dist = math.floor(vector.distance(pos, opos))
                
                if dist <= 50 then 
                    local color = "#FFFFFF"
                    if dist <= 10 then 
                        color = "#FF5555" 
                    elseif dist <= 30 then 
                        color = "#FFFF55" 
                    end
                    
                    local text_line = minetest.colorize(color, other:get_player_name() .. " [" .. dist .. "m]")
                    table.insert(nearby, text_line)
                end
            end
        end

        local text = table.concat(nearby, "\n")
        player:hud_change(hud_ids[pname], "text", text)
    end
end)

rust_core.log("action", "Player distance HUD registered")