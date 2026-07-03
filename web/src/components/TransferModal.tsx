import { useEffect, useState } from 'react';
import type { Vehicle } from '../types';
import { VehicleImage } from './VehicleImage';

interface TransferModalProps {
  vehicle: Vehicle;
  onCancel: () => void;
  onConfirm: (targetPlayerId: number) => void;
  onInvalid: () => void;
}

export function TransferModal({
  vehicle,
  onCancel,
  onConfirm,
  onInvalid,
}: TransferModalProps) {
  const [targetPlayerId, setTargetPlayerId] = useState('');

  // Reset the input whenever a new vehicle is targeted.
  useEffect(() => {
    setTargetPlayerId('');
  }, [vehicle]);

  const submit = () => {
    const id = parseInt(targetPlayerId, 10);
    if (!targetPlayerId || Number.isNaN(id) || id < 1) {
      onInvalid();
      return;
    }
    onConfirm(id);
  };

  return (
    <div className="modal">
      <div className="modal-overlay" onClick={onCancel} />
      <div className="modal-content">
        <div className="modal-header">
          <h2>Transfer Vehicle</h2>
          <button className="modal-close" onClick={onCancel}>
            &times;
          </button>
        </div>
        <div className="modal-body">
          <div className="transfer-info">
            <div className="transfer-vehicle-info">
              <VehicleImage
                vehicle={vehicle}
                alt="Vehicle"
                className="transfer-vehicle-img"
              />
              <div>
                <div className="transfer-vehicle-name">{vehicle.label}</div>
                <div className="transfer-vehicle-plate">{vehicle.plate}</div>
              </div>
            </div>
          </div>
          <div className="form-group">
            <label htmlFor="target-player-id">Target Player Server ID</label>
            <input
              id="target-player-id"
              type="number"
              min="1"
              placeholder="Enter player server ID (e.g., 1, 2, 3...)"
              value={targetPlayerId}
              onChange={(e) => setTargetPlayerId(e.target.value)}
              onKeyUp={(e) => {
                if (e.key === 'Enter') submit();
              }}
            />
            <small>
              Enter the server ID of the player you want to transfer this vehicle
              to
            </small>
          </div>
        </div>
        <div className="modal-footer">
          <button className="btn-cancel" onClick={onCancel}>
            Cancel
          </button>
          <button className="btn-confirm" onClick={submit}>
            Transfer Vehicle
          </button>
        </div>
      </div>
    </div>
  );
}
