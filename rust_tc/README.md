# rust_tc

Tool Cupboard for **Rust Survival**.

## What it does

- **Ownership.** Placing a TC makes you its owner.
- **Authorization.** Owner can `/rust_tc_auth <player>` to allow access to containers/doors inside the radius.
- **Radius protection (20 blocks default).** Unauthorized players cannot right-click chests, furnaces, or doors inside the radius.
- **Place protection.** Unauthorized players cannot place `rust_building` blocks inside the radius.
- **Upkeep & Decay.** Bases consume points hourly. Deposit resources into the TC to keep it alive. Without resources, bases take 4% HP damage per hour.
- **Raid target.** TC has HP (5000 default = 10 C4). Destroying it cleans up storage and disables authorization for that area.

## Craft

20 wood + 10 stone + 4 steel → 1 TC

## Commands

| Command | Who | What |
|---|---|---|
| `/rust_tc_auth <player>` | owner | Authorize a player |
| `/rust_tc_unauth <player>` | owner | Remove authorization |
| `/rust_tc_info` | anyone near TC | Show TC info |
| `/rust_tc_list` | anyone | List TCs you own |
| `/rust_tc_admin list` | server | List all TCs |
| `/rust_tc_admin info <id>` | server | Dump TC JSON |
| `/rust_tc_admin delete <id>` | server | Force-remove a TC |

## License

- **Code:** GPL-3.0-only (see `LICENSE` file)
- **Textures:** CC BY-SA 4.0 (see `MEDIA_LICENSE` file) (© 2026 8a7l)