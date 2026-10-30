-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 8a7l

-- rust_core/log.lua
-- Prefixed logging helper. All RustCraft mods log through this
-- so that grep "[rust_core]" or "[rust_hardcore]" in debug.txt
-- gives a complete picture per mod.

local prefix = "[rust_core] "

function rust_core.log(level, msg)
    minetest.log(level, prefix .. tostring(msg))
end

-- Shortcut for warnings: rust_core.warn(msg)
function rust_core.warn(msg)
    minetest.log("warning", prefix .. tostring(msg))
end