import { useCallback, useEffect, useMemo, useState } from 'react';
import type { OpenGaragePayload, Vehicle } from './types';
import { fetchNui } from './nui';
import { useNuiEvent } from './hooks/useNuiEvent';
import { VehicleItem } from './components/VehicleItem';
import { TransferModal } from './components/TransferModal';

export default function App() {
  const [isOpen, setIsOpen] = useState(false);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [garageIndex, setGarageIndex] = useState<OpenGaragePayload['garageIndex']>(
    null,
  );
  const [transferAllowed, setTransferAllowed] = useState(true);
  const [search, setSearch] = useState('');
  const [transferVehicle, setTransferVehicle] = useState<Vehicle | null>(null);

  const closeGarage = useCallback(() => {
    setIsOpen(false);
    setVehicles([]);
    setGarageIndex(null);
    setTransferVehicle(null);
    fetchNui('closeUI');
  }, []);

  const closeTransferModal = useCallback(() => {
    setTransferVehicle(null);
  }, []);

  useNuiEvent<OpenGaragePayload>('openGarage', (data) => {
    setVehicles(data.vehicles || []);
    setGarageIndex(data.garageIndex);
    setTransferAllowed(data.allowTransfer !== false);
    setSearch('');
    setTransferVehicle(null);
    setIsOpen(true);
    fetchNui('enableCursor');
  });

  useNuiEvent('closeGarage', () => {
    closeGarage();
  });

  // ESC closes the transfer modal first, otherwise the garage.
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return;
      if (transferVehicle) {
        closeTransferModal();
      } else {
        closeGarage();
      }
    };
    window.addEventListener('keyup', onKey);
    return () => window.removeEventListener('keyup', onKey);
  }, [isOpen, transferVehicle, closeGarage, closeTransferModal]);

  const filtered = useMemo(() => {
    const term = search.toLowerCase();
    if (!term) return vehicles;
    return vehicles.filter(
      (v) =>
        v.label.toLowerCase().includes(term) ||
        v.plate.toLowerCase().includes(term),
    );
  }, [vehicles, search]);

  const handleTakeout = useCallback(
    (vehicle: Vehicle) => {
      if (vehicle.state === 'in_garage' || vehicle.state === 'in_impound') {
        fetchNui('takeOutVehicle', { garageIndex, vehicle });
        closeGarage();
      } else if (vehicle.state === 'out_garage') {
        fetchNui('locateVehicle', { vehicle });
      }
    },
    [garageIndex, closeGarage],
  );

  const handleTransfer = useCallback(
    (vehicle: Vehicle) => {
      if (!transferAllowed) {
        fetchNui('showNotification', {
          message: 'Vehicle transfer is disabled',
          type: 'error',
        });
        return;
      }
      setTransferVehicle(vehicle);
    },
    [transferAllowed],
  );

  const confirmTransfer = useCallback(
    (targetPlayerId: number) => {
      if (!transferVehicle) {
        closeTransferModal();
        return;
      }
      fetchNui('transferVehicle', {
        vehicle: transferVehicle,
        targetPlayerId,
      });
      closeTransferModal();
      closeGarage();
    },
    [transferVehicle, closeTransferModal, closeGarage],
  );

  const onInvalidTransfer = useCallback(() => {
    fetchNui('showNotification', {
      message: 'Please enter a valid player server ID',
      type: 'error',
    });
  }, []);

  if (!isOpen) return null;

  return (
    <>
      <div id="garage-container">
        <div className="garage-wrapper">
          <div className="search-container">
            <input
              id="search-input"
              type="text"
              placeholder="Search vehicle by plate or name"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div className="vehicles-list" id="vehicles-list">
            {filtered.length === 0 ? (
              <div className="no-vehicles">No vehicles found</div>
            ) : (
              filtered.map((vehicle, index) => (
                <VehicleItem
                  key={`${vehicle.plate}-${index}`}
                  vehicle={vehicle}
                  onTakeout={handleTakeout}
                  onTransfer={handleTransfer}
                />
              ))
            )}
          </div>

          <div className="footer">
            <span id="vehicle-count">Total vehicles: {filtered.length}</span>
          </div>
        </div>
      </div>

      {transferVehicle && (
        <TransferModal
          vehicle={transferVehicle}
          onCancel={closeTransferModal}
          onConfirm={confirmTransfer}
          onInvalid={onInvalidTransfer}
        />
      )}
    </>
  );
}
