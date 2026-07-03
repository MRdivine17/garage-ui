import type { CSSProperties } from 'react';
import { Icon, type IconName } from './Icon';
import { useCountUp } from '../hooks/useCountUp';

type FillKind = 'fuel' | 'engine' | 'body';

interface StatBarProps {
  icon: IconName;
  label: string;
  percent: number;
  kind: FillKind;
}

export function StatBar({ icon, label, percent, kind }: StatBarProps) {
  const value = useCountUp(percent);
  const fillStyle = { '--fill-width': `${percent}%` } as CSSProperties;

  return (
    <div className="stat-bar">
      <div className="stat-label">
        <div className="stat-label-left">
          <Icon name={icon} className="stat-icon" />
          <span>{label}</span>
        </div>
        <span className="stat-value" data-value={percent}>
          {value}%
        </span>
      </div>
      <div className="stat-progress">
        <div
          className={`stat-fill ${kind}`}
          style={fillStyle}
          data-percent={percent}
        />
      </div>
    </div>
  );
}
