# rust_hardcore

Hardcore death and respawn for **RustCraft**.

## What it does (Stage 1)

- **100% death drop**: on death, all inventory items spill
  onto the ground at the death position. No bones, no safe
  containers.
- **Random respawn**: on death, player teleports to a random
  land position within `rust_hardcore_respawn_range` blocks
  of origin.
- **Raid window API**: `rust_hardcore.is_raid_window()` returns
  true during configurable hours (default 19:00-07:00). Stage 2
  (`rust_raid`) will call this before allowing explosives.

## Install order

`rust_core` must load first. Then `rust_hardcore`. Then everything
else.

**Important — conflict with `bones` mod (default game):**
`bones` also registers an `on_dieplayer` handler. If both run,
the *first* handler wins (drops items), the second sees an empty
inventory and does nothing.

To get pure RustCraft behavior, **either**:
- disable `bones` in `worlds/<world>/world.mt`: `bones = false`
- **or** list `rust_hardcore` before `bones` in `mods.conf`

## Recommended `minetest.conf` overrides for Rust gameplay
