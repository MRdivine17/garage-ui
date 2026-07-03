# Qbox (qbx_core) installation

This resource now ships a native **Qbox** framework adapter
(`framework/qbox/`). It loads automatically when `qbx_core` is running and
reports itself internally as `qb-core`, so it reuses the QB data path
(`player_vehicles` keyed by `citizenid`).

## Steps

1. **Dependencies** (all already standard on a Qbox server):
   `qbx_core`, `ox_lib`, `oxmysql`, `ox_inventory`.
   Optional but supported: `qbx_vehiclekeys` (keys), `ox_fuel` (fuel),
   `ox_target` (targeting).

2. **Database** — import `install/qbox.sql`. It adds the columns this
   resource needs (`job`, `type`, `stored`, `vehicle_image`,
   `engine_health`, `body_health`) to Qbox's existing `player_vehicles`
   table. Safe to re-run.

3. **Contract item** (only needed if you use vehicle selling/transfer via
   the `contract` item). Add it to your **ox_inventory** items
   (`ox_inventory/data/items.lua`):

   ```lua
   ['contract'] = {
       label = 'Contract',
       weight = 100,
       stack = true,
       close = false,
       description = 'Used for selling/transfering vehicles.',
       client = { image = 'contract.png' }
   },
   ```

   Copy `install/images/contract.png` into `ox_inventory/web/images/`.

4. **Build the UI** (already built, only needed if you edit it):
   `cd web && npm install && npm run build`.

5. **Ensure the resource** in your `server.cfg` (after `qbx_core`,
   `ox_lib`, `ox_inventory`, `oxmysql`).

## Notes

- Keys: with `Framework.name = 'qb-core'`, `config/cl_edit.lua` fires
  `vehiclekeys:client:SetOwner`, which `qbx_vehiclekeys` handles through
  its qb compatibility bridge — no extra config needed.
- Fuel: `config/cl_edit.lua` reads/writes the `fuel` statebag used by
  `ox_fuel` (with a native fallback), so restored vehicles keep their fuel.
- The Qbox bridge convar `qbx:enablebridge` is **not** required — the
  adapter uses native `qbx_core` exports, not the qb-core compat bridge.
