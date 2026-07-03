# Garage UI (React + Vite + TypeScript)

NUI frontend for the garage resource. Rewritten from the legacy
`html/` (jQuery) UI into React + Vite + TypeScript. Same look, same
behaviour, same NUI message contract.

## Commands

```bash
npm install      # once
npm run dev      # local preview at http://localhost:5173 (mock data auto-loads)
npm run build    # type-check + production build into web/dist
```

`fxmanifest.lua` serves `web/dist/index.html` as the `ui_page`. After any
UI change, run `npm run build` and restart the resource in-game.

## How it maps to FiveM

- `base: './'` in `vite.config.ts` — required so built assets load over
  `nui://` with relative paths.
- Incoming messages (`window.postMessage`): `openGarage`, `closeGarage`
  (see `src/hooks/useNuiEvent.ts`, `src/App.tsx`).
- Outgoing callbacks (`fetchNui` in `src/nui.ts`): `enableCursor`,
  `closeUI`, `takeOutVehicle`, `locateVehicle`, `showNotification`,
  `transferVehicle`. Resource name is resolved via
  `GetParentResourceName()` with a `lunar_garage` fallback.

## Structure

```
src/
  App.tsx                 state + NUI wiring
  nui.ts                  fetchNui / resource-name resolution
  types.ts                Vehicle / message types
  dev.ts                  DEV-only mock (stripped from production build)
  hooks/
    useNuiEvent.ts        subscribe to postMessage by action
    useCountUp.ts         stat number count-up (1.5s / 60 steps)
  components/
    VehicleItem.tsx       card + expand + stats + actions
    StatBar.tsx           fuel/engine/body bar
    VehicleImage.tsx      image with fallback chain -> icon
    TransferModal.tsx     transfer dialog
    Icon.tsx              inline SVG icon set
  styles/global.css       ported 1:1 from the old style.css
```

The legacy `html/` files are left in place as reference but are no longer
loaded by the manifest.
