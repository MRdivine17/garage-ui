import type { OpenGaragePayload } from './types';

// Development-only mock: fires an openGarage message so the layout is visible
// in a plain browser. Stripped from production because main.tsx only imports
// this module when import.meta.env.DEV is true.
const sample: OpenGaragePayload = {
  action: 'openGarage',
  garageIndex: 1,
  society: false,
  allowTransfer: true,
  vehicles: [
    {
      label: 'Pfister Comet',
      plate: 'DEV 1001',
      modelName: 'comet2',
      state: 'in_garage',
      fuelLevel: 82,
      engineHealth: 940,
      bodyHealth: 880,
    },
    {
      label: 'Bravado Banshee',
      plate: 'DEV 1002',
      modelName: 'banshee',
      state: 'out_garage',
      fuelLevel: 34,
      engineHealth: 620,
      bodyHealth: 710,
      location: { x: 215.7, y: -810.2, z: 30.7 },
    },
    {
      label: 'Ubermacht Sultan',
      plate: 'DEV 1003',
      modelName: 'sultan',
      state: 'in_impound',
      fuelLevel: 12,
      engineHealth: 150,
      bodyHealth: 90,
    },
  ],
};

window.setTimeout(() => {
  window.postMessage(sample, '*');
}, 300);
