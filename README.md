# Celestial Garden Defense

An original, Rojo 7.7-compatible Roblox tower-defense/simulator project. It uses only procedural placeholder geometry and original guardian, egg, and wildgrowth names.

## Source layout

| Location | Purpose |
| --- | --- |
| `src/server` | Server-authoritative world, commands, combat, inventory, economy, and persistence. |
| `src/client` | Responsive presentation/UI code only. |
| `src/shared/config` | Replicated read-only configurations for rarities, guardians, enemies, eggs, gear, and game constants. |

`default.project.json` maps those directories directly to `ServerScriptService`, `StarterPlayerScripts`, and `ReplicatedStorage.Shared`, respectively. Sync this project through the existing Rojo server; do not create a place file from this repository.

## Play loop

1. A player receives one of exactly four available garden bases and starts with one lane.
2. Buy an original egg at the Egg Shop, then start and claim its server-timed hatch at Hatch Bay.
3. Place the new guardian in an unlocked lane. A lane has five slots and guardians only attack that lane's active wildgrowth.
4. Earn coins from kills, unlock lanes, buy upgrades, hatch stronger eggs, sell duplicates, and complete the Index.

## Trust boundaries

The client receives inventory snapshots and requests actions, but it never controls prices, money, rewards, rolls, stats, ownership, lane unlocks, or save data. `Main.server.luau` validates station proximity and item ownership before mutations; `DataService` uses guarded `UpdateAsync` retries and shutdown/player-leave saves.
