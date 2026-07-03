import { useEffect, useState } from 'react';

/**
 * Counts up from 0 to `target` over `duration` ms in `steps` increments.
 * Matches the legacy animateStats() timing (1.5s / 60 steps).
 */
export function useCountUp(
  target: number,
  duration = 1500,
  steps = 60,
): number {
  const [value, setValue] = useState(0);

  useEffect(() => {
    let current = 0;
    const increment = target / steps;
    const stepDuration = duration / steps;
    setValue(0);

    const id = window.setInterval(() => {
      current += increment;
      if (current >= target) {
        current = target;
        window.clearInterval(id);
      }
      setValue(Math.round(current));
    }, stepDuration);

    return () => window.clearInterval(id);
  }, [target, duration, steps]);

  return value;
}
