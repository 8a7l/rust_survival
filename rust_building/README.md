# rust_building

Tiered building blocks with HP for **Rust Survival**.

## Tiers

| Tier | HP | Craft | Drop on destroy |
|---|---|---|---|
| Wood | 250 | 4 wood | 1 wood |
| Stone | 1000 | 4 stone | 1 stone |
| Metal | 2000 | 4 steel_ingot | 1 steel_ingot |
| Armored | 4000 | 4 steel_ingot + 4 diamond | 1 steel_ingot |

HP values are configurable in `settingtypes.txt`.

## Behaviour

- **Players cannot dig these blocks with tools.** Standard digging is disabled (`diggable = false`). Instead, players must punch the block **150 times** to break it.
- **Only `rust_building.damage_node(pos, amount, dtype)` can destroy them via API.**
  This is the API `rust_raid` calls from explosives.
- **Foreign `dig_node` is reverted.** If another mod digs a block (e.g. a TNT mod using `dig_node`), the block is re-placed with its last known HP and a warning is logged.

## License

GPL-3.0-only. See SPDX headers in each file.