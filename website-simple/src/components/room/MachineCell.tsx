import { formatDistanceToNow } from 'date-fns';
import { motion } from 'framer-motion';
import { Tooltip } from '@mantine/core';
import { convertMachineStatusToString, MachineStatusOverview } from '@/types/datatypes';
import { shortMachineLabel } from '@/utils/helpers';
import { StatusBadge } from '@/components/machine/StatusBadge';
import { cn } from '@/lib/utils';

interface MachineCellProps {
  machine: MachineStatusOverview;
  onClick: () => void;
  className?: string;
  isStale?: boolean;
}

/**
 * MachineCell component displays a compact machine status card
 * Layout:
 * ┌─────────┐
 * │ W1   🟢 │  ← Label + status badge
 * │ 2m      │  ← Time since update
 * └─────────┘
 */
export function MachineCell({ machine, onClick, className, isStale: _isStale }: MachineCellProps) {
  const isStale = false; // TODO: fix manual override now that we handle stale state from the Backend
  const since = machine.lastChangeTime || machine.lastUpdated;
  const timeAgo = formatDistanceToNow(new Date(since), {
    addSuffix: false,
  })
    .replace('about ', '')
    .replace('less than a minute', '<1m')
    .replace(' minutes', 'm')
    .replace(' minute', 'm')
    .replace(' hours', 'h')
    .replace(' hour', 'h');

  const timeTo = machine.currentCycleTime && machine.lastAvailableTime ? formatDistanceToNow(new Date(new Date(machine.lastAvailableTime).getTime() + machine.currentCycleTime * 60000), {
    addSuffix: false,
  }).replace('about ', '')
    .replace('less than a minute', '<1m')
    .replace(' minutes', 'm')
    .replace(' minute', 'm')
    .replace(' hours', 'h')
    .replace(' hour', 'h') : null;
  const statusDisplay = convertMachineStatusToString(machine.currentStatus);
  const staleTooltip = isStale
    ? `⚠️ Data may not be accurate - sensor appears offline`
    : `${shortMachineLabel(machine.label, machine.type, machine.name)} • ${statusDisplay} • Updated ${timeAgo} ago`;

  return (
    <Tooltip
      label={staleTooltip}
      multiline
      maw={300}
      withArrow
      arrowPosition="center"
    >
      <motion.button
        onClick={onClick}
        className={cn(
          'group relative flex h-[88px] flex-col items-start justify-between overflow-hidden',
          'rounded-md border-2 border-dark-border bg-dark-surface p-3',
          'hover:border-accent-dark hover:bg-dark-border',
          'dark:border-light-border dark:bg-light-surface',
          'dark:hover:border-accent-light dark:hover:bg-light-border',
          'transition-all duration-200',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-dark dark:focus-visible:ring-accent-light',
          isStale && 'grayscale opacity-60',
          className
        )}
        whileHover={!isStale ? { scale: 1.02 } : undefined}
        whileTap={!isStale ? { scale: 0.98 } : undefined}
        aria-label={`View details for ${shortMachineLabel(machine.label, machine.type, machine.name)}`}
      >
        {/* Top row: Label + Status Badge */}
        <div className="flex w-full min-w-0 items-center justify-between gap-2">
          <span className="min-w-0 truncate font-mono text-base font-semibold text-dark-text-primary dark:text-light-text-primary">
            {shortMachineLabel(machine.label, machine.type, machine.name)}
          </span>

        </div>

        <div className="flex w-full min-w-0 items-center justify-between gap-2">
          <StatusBadge status={machine.currentStatus} size="md" className='flex shrink-0' />
          <span className="font-mono text-xs text-dark-text-secondary dark:text-light-text-secondary">
            {timeTo ? `${timeTo} left` : `${timeAgo} ago`}
          </span>
        </div>

        {/* Bottom row: Time since status change */}

      </motion.button>
    </Tooltip>
  );
}
