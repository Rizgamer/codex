# Celestial Garden Defense

A Rojo-ready Roblox tower-defense/simulator foundation built entirely from original placeholder geometry and original character/enemy names. Open `default.project.json` with Rojo, sync into a Roblox place, and enable API Services in Studio to exercise persistence.

## Play loop
1. Each server generates exactly four claimable garden bases (one player per base).
2. Stand on the Egg Shop platform to buy a `Starter Bloom`, then move to Hatch Bay and begin/claim the server-timed hatch.
3. Open Inventory and place the hatched guardian into an unlocked lane. Lanes hold five guardians maximum and only target their own lane.
4. Defeat advancing wildgrowth for coins, unlock lanes, buy upgrades, hatch stronger eggs, sell duplicate captures, and fill the Index.

## Security/architecture
- `MainServer.server.lua` is the sole command gateway and validates ownership, base ownership, proximity, configured prices, lane limits, and server-side rolls.
- `DataService` uses `UpdateAsync`, retries, profile validation, `PlayerRemoving`, and `BindToClose` saving.
- Config ModuleScripts centralize rarities, egg pools, guardians, wildgrowth enemies, gear, and economy values.
- The client receives snapshots only; it cannot select rewards, money values, damage, prices, or rarity outcomes.
