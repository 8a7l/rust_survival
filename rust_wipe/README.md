# rust_wipe

World wipe logic for **Rust Survival**.

## Features

- **Soft Wipe (manual):** `/rust_wipe confirm` instantly clears all bases, TCs, and online player inventories. Offline players are cleared on next login.
- **Auto-Wipe (optional):** If enabled, the server will wipe itself every `N` days (default 7). Creates a `WIPE_MAP.txt` marker in the world folder to trigger a hard map wipe on the next server restart.
- **Lazy Wipe:** Unloaded chunks are not loaded just for wiping. Instead, a LBM (`rust_wipe:lazy_cleanup`) removes any blocks from the old generation when they are next loaded.

## Commands

- `/rust_wipe confirm` — Force a soft wipe immediately.
- `/rust_wipe_status` — Check when the next auto-wipe will happen.