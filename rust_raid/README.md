# rust_raid

Explosives for **Rust Survival**.

## Items

| Item | Damage | Radius | Fuse | Recipe |
|---|---|---|---|---|
| Gunpowder | — | — | — | 1 coal + 1 sand → 2 |
| Satchel | 100 | 3 | 5s | 3 gunpowder + 1 paper |
| C4 | 500 | 4 | 3s | 6 gunpowder + 2 steel + 1 diamond |
| Landmine | 300 | 2 | Contact | 3 gunpowder + 3 steel + 1 mese fragment |

## What explosions damage

| Block type | Damaged? | Drop |
|---|---|---|
| `rust_building:*` | ✅ HP-based | block item |
| `default:chest`, `chest_locked` | ✅ 200 HP | contents + item (vanilla) |
| `default:furnace(_active)` | ✅ 200 HP | contents + item (vanilla) |
| `doors:*`, `*:gate_*` | ✅ 200 HP | both halves (vanilla) |
| **Natural terrain** | ❌ no | untouched |

## Raid window

Explosions and Landmines only work when `rust_hardcore.is_raid_window()` is true. A "dud" explosion (out of window) does not damage anything and is logged. Use `/rust_raid_status` to check.

## Players

Players within the blast radius take `building_damage * 0.35` (35%). They are also violently knocked back (diagonally upwards). 
* Satchel at center: 35 HP (death). 
* C4 at center: 175 HP (instant death).

## Mines

Landmines are flat, placed on the ground, and explode when a non-authorized player steps on them during the Raid Window. They deal 300 damage in a 2-block radius.

## Admin commands

- `/rust_raid_test <radius> <damage>` — trigger test explosion
- `/rust_raid_status` — current raid window status
- `/rust_raid_register_breakable <node> [hp]` — add custom breakable
- `/rust_raid_breakables` — list all breakables

---

## License & Credits

- **Code:** GPL-3.0-only (see `LICENSE` file)
- **Textures:** CC BY-SA 4.0 (see `MEDIA_LICENSE` file) (© 2026 8a7l)
- **Sounds:** 
  - `rust_raid_explode.ogg` — CC0 (Creative Commons 0)
  - Source: [https://freesound.org/s/500795/](https://freesound.org/s/500795/)