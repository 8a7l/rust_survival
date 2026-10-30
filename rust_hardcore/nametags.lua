-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_hardcore/nametags.lua
-- Повністю ховаємо імена над головами гравців для хардкору.

minetest.register_on_joinplayer(function(player)
    -- Робимо текст повністю прозорим (всі 4 компоненти RGBA)
    player:set_nametag_attributes({
        text = "",
        color = {r = 0, g = 0, b = 0, a = 0}
    })
end)

rust_core.log("action", "Nametags hidden (Hardcore mode)")