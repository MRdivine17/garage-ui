import { useMemo, useState } from 'react';
import type { Vehicle } from '../types';

/** Primary image: DB custom URL, else FiveM CDN webp. Mirrors getVehicleImage(). */
export function getVehicleImage(vehicle: Vehicle): string {
  if (vehicle.customImage && vehicle.customImage.trim() !== '') {
    return vehicle.customImage;
  }
  const modelName = (vehicle.modelName || 'adder').toLowerCase();
  return `https://docs.fivem.net/vehicles/${modelName}.webp`;
}

/** Ordered fallback chain matching the legacy handleImageError() sequence. */
function buildSources(vehicle: Vehicle): string[] {
  const modelName = (vehicle.modelName || 'adder').toLowerCase();
  return [
    getVehicleImage(vehicle),
    `vehicles/${modelName}.webp`,
    `vehicles/${modelName}.png`,
    `vehicles/${modelName}.jpg`,
    `https://docs.fivem.net/vehicles/adder.webp`,
  ];
}

const FallbackIcon = () => (
  <div className="fallback-icon">
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="32"
      height="32"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M14 16H9m10 0h3v-3.15a1 1 0 0 0-.84-.99L16 11l-2.7-3.6a1 1 0 0 0-.8-.4H5.24a2 2 0 0 0-1.8 1.1l-.8 1.63A6 6 0 0 0 2 12.42V16h2" />
      <circle cx="6.5" cy="16.5" r="2.5" />
      <circle cx="16.5" cy="16.5" r="2.5" />
    </svg>
  </div>
);

interface VehicleImageProps {
  vehicle: Vehicle;
  alt: string;
  className: string;
}

export function VehicleImage({ vehicle, alt, className }: VehicleImageProps) {
  const sources = useMemo(() => buildSources(vehicle), [vehicle]);
  const [index, setIndex] = useState(0);

  if (index >= sources.length) {
    return <FallbackIcon />;
  }

  return (
    <img
      src={sources[index]}
      alt={alt}
      className={className}
      data-model={(vehicle.modelName || 'adder').toLowerCase()}
      onError={() => setIndex((i) => i + 1)}
    />
  );
}
