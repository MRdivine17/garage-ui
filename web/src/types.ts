export type VehicleState = 'in_garage' | 'out_garage' | 'in_impound';

export interface Vehicle {
  label: string;
  plate: string;
  modelName?: string;
  customImage?: string;
  state: VehicleState;
  fuelLevel?: number;
  engineHealth?: number;
  bodyHealth?: number;
  location?: { x: number; y: number; z?: number };
}

export interface OpenGaragePayload {
  action: 'openGarage';
  vehicles: Vehicle[];
  garageIndex: number | string | null;
  society?: boolean;
  allowTransfer?: boolean;
}

export interface CloseGaragePayload {
  action: 'closeGarage';
}

export type NuiMessage = OpenGaragePayload | CloseGaragePayload;
