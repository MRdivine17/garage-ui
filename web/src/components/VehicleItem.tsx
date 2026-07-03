import { useState } from 'react';
import type { Vehicle } from '../types';
import { Icon, type IconName } from './Icon';
import { VehicleImage } from './VehicleImage';
import { StatBar } from './StatBar';

function getStatusText(state: Vehicle['state']): string {
  switch (state) {
    case 'in_garage':
      return '✓ Available in Garage';
    case 'out_garage':
      return '📍 Vehicle is Out - Click Locate';
    case 'in_impound':
      return '🚫 Vehicle Not Found - Impounded';
    default:
      return 'Unknown';
  }
}

interface VehicleItemProps {
  vehicle: Vehicle;
  onTakeout: (vehicle: Vehicle) => void;
  onTransfer: (vehicle: Vehicle) => void;
}

export function VehicleItem({ vehicle, onTakeout, onTransfer }: VehicleItemProps) {
  const [expanded, setExpanded] = useState(false);

  // Preserve legacy `|| default` semantics exactly (0 falls back to default).
  const fuelLevel = vehicle.fuelLevel || 100;
  const engineHealth = vehicle.engineHealth || 1000;
  const bodyHealth = vehicle.bodyHealth || 1000;

  const fuelPercent = Math.round(fuelLevel);
  const enginePercent = Math.round((engineHealth / 1000) * 100);
  const bodyPercent = Math.round((bodyHealth / 1000) * 100);

  let buttonText: string;
  let buttonIcon: IconName;
  let buttonClass: string;
  if (vehicle.state === 'in_impound') {
    buttonText = 'Retrieve';
    buttonIcon = 'package-check';
    buttonClass = 'btn-retrieve';
  } else if (vehicle.state === 'out_garage') {
    buttonText = 'Locate';
    buttonIcon = 'map-pin';
    buttonClass = 'btn-locate';
  } else {
    buttonText = 'Take Out';
    buttonIcon = 'car-front';
    buttonClass = 'btn-takeout';
  }

  let statusClass = 'available';
  if (vehicle.state === 'out_garage') statusClass = 'out';
  if (vehicle.state === 'in_impound') statusClass = 'impounded';

  const transferDisabled = vehicle.state !== 'in_garage';

  return (
    <div className={`vehicle-item${expanded ? ' expanded' : ''}`}>
      <div
        className="vehicle-header"
        onClick={(e) => {
          e.stopPropagation();
          setExpanded((v) => !v);
        }}
      >
        <div className="vehicle-info">
          <div className="vehicle-image-container">
            <VehicleImage
              vehicle={vehicle}
              alt={vehicle.label}
              className="vehicle-image"
            />
          </div>
          <div className="vehicle-text">
            <div className="vehicle-name">{vehicle.label}</div>
            <div className={`vehicle-status ${statusClass}`}>
              {getStatusText(vehicle.state)}
            </div>
          </div>
        </div>
        <div className="vehicle-plate">{vehicle.plate}</div>
      </div>

      {expanded && (
        <div className="vehicle-details">
          <div className="stats-container">
            <StatBar icon="fuel" label="Fuel" percent={fuelPercent} kind="fuel" />
            <StatBar
              icon="gauge"
              label="Engine"
              percent={enginePercent}
              kind="engine"
            />
            <StatBar icon="shield" label="Body" percent={bodyPercent} kind="body" />
          </div>
          <div className="actions-container">
            <button
              className={`action-btn ${buttonClass}`}
              onClick={(e) => {
                e.stopPropagation();
                onTakeout(vehicle);
              }}
            >
              <Icon name={buttonIcon} />
              {buttonText}
            </button>
            <button
              className="action-btn btn-transfer"
              disabled={transferDisabled}
              title={
                transferDisabled
                  ? 'Vehicle must be in garage to transfer'
                  : undefined
              }
              onClick={(e) => {
                e.stopPropagation();
                onTransfer(vehicle);
              }}
            >
              <Icon name="arrow-right-left" />
              Transfer
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
