-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/join.lua
-- Spawn rescue: витягує гравця, якщо він застряг у ПОВНОЦІННОМУ твердому блоці.

local function node_is_solid(p)
    local n = minetest.get_node_or_nil(p)
    if not n then return false end
    local d = minetest.registered_nodes[n.name]
    if not d or not d.walkable then return false end
    
    -- ВАЖЛИВО: Ігноруємо тонкі блоки (сніг, плити, сходи)
    -- Вважаємо перешкодою лише повні куби (drawtype = "normal" або "allfaces")
    if d.drawtype == "nodebox" or d.drawtype == "mesh" then
        return false
    end
    
    return true
end

local function is_stuck(pos)
    local x = math.floor(pos.x)
    local z = math.floor(pos.z)
    local y_body = math.floor(pos.y + 0.5)
    local y_head = math.floor(pos.y + 1.5)
    
    if node_is_solid({x = x, y = y_body, z = z}) then return true end
    if node_is_solid({x = x, y = y_head, z = z}) then return true end
    return false
end

minetest.register_on_joinplayer(function(player)
    minetest.after(1.0, function()
        if not player or not player:is_player() then return end
        
        local pos = player:get_pos()
        if not pos then return end
        if not is_stuck(pos) then return end

        local new_pos = rust_hardcore.find_random_land()
        if not new_pos then
            rust_core.warn("Join rescue: " .. player:get_player_name() ..
                " is stuck at " .. minetest.pos_to_string(pos) ..
                " but no land found.")
            return
        end

        player:set_pos(new_pos)
        rust_core.log("action", "Join rescue: " ..
            player:get_player_name() ..
            " moved from " .. minetest.pos_to_string(pos) ..
            " to " .. minetest.pos_to_string(new_pos))
    end)
end)

rust_core.log("action", "Join spawn rescue registered (ignores slabs/snow)")