# rust_core

Foundation mod for **RustCraft**. Provides logging, config,
schema versioning, and a small public API for other `rust_*` mods.

## API (for mod authors)

- `rust_core.log(level, msg)` — prefixed `minetest.log`
- `rust_core.warn(msg)` — shortcut for warnings
- `rust_core.config.*` — global defaults (wipe cycle, log level)
- `rust_core.db.get_string / set_string / get_int / set_int / get_float / set_float`
- `rust_core.register_tag(name, desc)` / `rust_core.has_tag(stack, tag)`
- `rust_core.get_hour()` — current in-game hour [0, 24)
- `rust_core.get_day()` — elapsed in-game days

## License

GPL-3.0-only. See SPDX headers in each file.