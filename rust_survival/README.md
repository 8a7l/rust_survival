# rust_survival (meta-mod)

This is the **single toggle** for the Rust Survival modpack.

Do not add gameplay here. Its only purpose is to `depends` on
every Rust Survival component, so players/admins enable just one
mod in the world configuration.

## Adding a new component

1. Drop the new mod into `mods/rust_survival/` (e.g. `rust_raid/`).
2. Add its name to `depends` in `mod.conf` here.
3. Done — no `world.mt` edit, no reordering.