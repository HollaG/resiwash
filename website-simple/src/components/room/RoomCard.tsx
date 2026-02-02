import { formatDistanceToNow } from 'date-fns';
import { useMemo, useState } from 'react';
import { Tooltip } from '@mantine/core';
import { MachineStatusOverview, MachineStatus } from '@/types/datatypes';
import { StatusBadge } from '@/components/machine/StatusBadge';
import { MachineGrid } from './MachineGrid';
import { MachineCell } from './MachineCell';
import { getMachineSlotKey, getMachineSlotNumber, shortMachineLabel } from '@/utils/helpers';
import toast from 'react-hot-toast';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface RoomCardProps {
  areaName: string;
  roomId: number;
  roomName: string;
  machines: MachineStatusOverview[];
  onMachineClick: (machineId: number) => void;
  isPinned?: boolean;
  className?: string;
}

/**
 * RoomCard component displays a room with its machines
 * Layout:
 * ╔═══════════════════════════════════╗
 * ║ FLOOR 3 LAUNDRY                   ║
 * ║ 4/7 AVAILABLE                     ║  ← Hero availability count
 * ║ ━━━━━━━━━━                        ║  ← Progress bar
 * ║                                   ║
 * ║ [MachineGrid]                     ║
 * ║                                   ║
 * ║ Updated 12s ago                   ║
 * ╚═══════════════════════════════════╝
 */
function sortMachinesBySlot(machines: MachineStatusOverview[]) {
  return [...machines].sort((a, b) => {
    const aNum = getMachineSlotNumber({ label: a.label, type: a.type, name: a.name });
    const bNum = getMachineSlotNumber({ label: b.label, type: b.type, name: b.name });

    if (aNum !== null && bNum !== null && aNum !== bNum) return aNum - bNum;

    return a.label.localeCompare(b.label);
  });
}

export function RoomCard({
  roomId,
  roomName,
  machines,
  onMachineClick,
  isPinned = false,
  className,
}: RoomCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const washers = machines.filter((m) => m.type === 'washer');
  const dryers = machines.filter((m) => m.type === 'dryer');

  const machineBySlot = useMemo(() => {
    if (roomId !== 3 && roomId !== 4) return new Map<string, MachineStatusOverview>();

    const map = new Map<string, MachineStatusOverview>();
    machines.forEach((machine) => {
      const key = getMachineSlotKey({ label: machine.label, type: machine.type, name: machine.name });
      if (!key) return;
      if (map.has(key)) return;
      map.set(key, machine);
    });

    return map;
  }, [machines, roomId]);

  const availableWashers = washers.filter(
    (m) => m.currentStatus === MachineStatus.AVAILABLE
  ).length;
  const availableDryers = dryers.filter(
    (m) => m.currentStatus === MachineStatus.AVAILABLE
  ).length;

  const sortedWashers = sortMachinesBySlot(washers);
  const sortedDryers = sortMachinesBySlot(dryers);

  const mostRecentChange = machines.reduce((latest, machine) => {
    const machineTime = new Date(machine.lastChangeTime || machine.lastUpdated).getTime();
    return machineTime > latest ? machineTime : latest;
  }, 0);

  const timeAgo = mostRecentChange
    ? formatDistanceToNow(new Date(mostRecentChange), { addSuffix: true })
    : 'Never';

  // Check if data is stale (older than 30 minutes)
  const oldestDataTime = machines.reduce((oldest, machine) => {
    const machineTime = new Date(machine.lastUpdated).getTime();
    return machineTime < oldest ? machineTime : oldest;
  }, Date.now());

  const isStale = Date.now() - oldestDataTime > 30 * 60 * 1000;

  return (
    <Card className={cn('overflow-hidden', isPinned && 'border-accent-dark dark:border-accent-light', className)}>
      <CardHeader className="space-y-4 pb-4">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-2xl font-bold uppercase tracking-tight text-dark-text-primary dark:text-light-text-primary">
            {roomName}
          </h2>
          <div className="flex items-center gap-2">
            {isStale && (
              <Tooltip
                label="Sensor offline, check back again!"
                withArrow
              >
                <span className="text-xs font-mono px-2 py-1 rounded bg-dark-border-inner text-secondary dark:bg-light-border-inner cursor-help">
                  OFFLINE
                </span>
              </Tooltip>
            )}
          </div>
        </div>

        <div className={cn("space-y-3", isStale && "grayscale opacity-60")} role="status" aria-live="polite">
          {/* Washers status bar */}
          <div className="flex items-center justify-between gap-4">
            <div className="w-24 shrink-0 font-mono text-sm font-semibold text-secondary">
              Washers
            </div>
            <div className="flex min-w-0 flex-1 items-center gap-3">
              {sortedWashers.length > 0 ? (
                <div className="flex min-w-0 flex-1 items-center gap-1.5 overflow-x-auto py-1">
                  {sortedWashers.map((machine) => (
                    <Tooltip
                      key={machine.machineId}
                      label={`${shortMachineLabel(machine.label, machine.type, machine.name)}: ${machine.currentStatus.replace(/_/g, ' ')}`}
                      withArrow
                    >
                      <div className="shrink-0">
                        <StatusBadge status={machine.currentStatus} size="md" />
                      </div>
                    </Tooltip>
                  ))}
                </div>
              ) : (
                <div className="min-w-0 flex-1 font-mono text-sm text-secondary">
                  No washers
                </div>
              )}
              <div className="shrink-0 font-mono text-sm font-bold text-primary">
                {availableWashers}/{washers.length}
              </div>
            </div>
          </div>

          {/* Dryers status bar */}
          <div className="flex items-center justify-between gap-4">
            <div className="w-24 shrink-0 font-mono text-sm font-semibold text-secondary">
              Dryers
            </div>
            <div className="flex min-w-0 flex-1 items-center gap-3">
              {sortedDryers.length > 0 ? (
                <div className="flex min-w-0 flex-1 items-center gap-1.5 overflow-x-auto py-1">
                  {sortedDryers.map((machine) => (
                    <Tooltip
                      key={machine.machineId}
                      label={`${shortMachineLabel(machine.label, machine.type, machine.name)}: ${machine.currentStatus.replace(/_/g, ' ')}`}
                      withArrow
                    >
                      <div className="shrink-0">
                        <StatusBadge status={machine.currentStatus} size="md" />
                      </div>
                    </Tooltip>
                  ))}
                </div>
              ) : (
                <div className="min-w-0 flex-1 font-mono text-sm text-secondary">
                  No dryers
                </div>
              )}
              <div className="shrink-0 font-mono text-sm font-bold text-primary">
                {availableDryers}/{dryers.length}
              </div>
            </div>
          </div>
        </div>
      </CardHeader>

      {isExpanded && (
        <CardContent className="space-y-4">
          {/* Machine grid */}
          {roomId === 3 ? (
            <div className="space-y-2">
              <div className="grid grid-cols-2 gap-2">
                <div className="font-mono text-xs font-semibold text-secondary">Dryers</div>
                <div className="font-mono text-xs font-semibold text-secondary">Washers</div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                {[
                  ['D6', 'W1'],
                  ['D5', 'W2'],
                  ['D4', 'W3'],
                  ['D3', 'W4'],
                  ['D2', 'W5'],
                  ['D1', 'W6'],
                  [null, 'W7'],
                  [null, 'W8'],
                ].flatMap(([dryerSlot, washerSlot], rowIndex) => {
                  const renderEmpty = (key: string) => (
                    <div key={key} className="h-[88px]" aria-hidden />
                  );

                   const renderMachineOrPlaceholder = (slot: string, key: string) => {
                     const machine = machineBySlot.get(slot);
                     if (machine) {
                       return (
                         <MachineCell
                           key={key}
                           machine={machine}
                           onClick={() => onMachineClick(machine.machineId)}
                           isStale={isStale}
                         />
                       );
                     }

                      return (
                        <button
                          key={key}
                          type="button"
                          onClick={() => toast(`Missing machine: ${slot}`)}
                          className={cn(
                            'group relative flex h-[88px] flex-col items-start justify-between overflow-hidden',
                            'rounded-md border-2 border-dashed border-dark-border-inner bg-dark-surface p-3',
                            'hover:border-accent-dark hover:bg-dark-border-inner',
                            'dark:border-light-border-inner dark:bg-light-surface',
                            'dark:hover:border-accent-light dark:hover:bg-light-border-inner',
                            'transition-all duration-200',
                            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-dark dark:focus-visible:ring-accent-light'
                          )}
                          aria-label={`Missing machine ${slot}`}
                        >
                          <span className="font-mono text-base font-semibold text-dark-text-primary dark:text-light-text-primary">
                            {slot}
                          </span>
                          <span className="font-mono text-xs text-dark-text-secondary dark:text-light-text-secondary">
                            Missing
                          </span>
                        </button>
                      );
                    };

                    return [
                     dryerSlot ? renderMachineOrPlaceholder(dryerSlot, `dryer-${dryerSlot}`) : renderEmpty(`dryer-empty-${rowIndex}`),
                     washerSlot ? renderMachineOrPlaceholder(washerSlot, `washer-${washerSlot}`) : renderEmpty(`washer-empty-${rowIndex}`),
                   ];
                 })}
               </div>
             </div>
           ) : roomId === 4 ? (
            <div className="space-y-2">
              <div className="grid grid-cols-4 gap-2">
                <div className="col-span-2 font-mono text-xs font-semibold text-secondary">Dryers</div>
                <div className="col-span-2 font-mono text-xs font-semibold text-secondary">Washers</div>
              </div>

              <div className="grid grid-cols-4 gap-2">
                {[
                  [null, 'D6', null, null],
                  ['D5', null, null, null],
                  ['D4', null, 'W5', 'W4'],
                  ['D3', null, 'W6', 'W3'],
                  ['D2', null, 'W7', 'W2'],
                  ['D1', null, 'W8', 'W1'],
                ].flatMap((row, rowIndex) => {
                  const renderEmpty = (key: string) => (
                    <div key={key} className="h-[88px]" aria-hidden />
                  );

                   const renderMachineOrPlaceholder = (slot: string, key: string) => {
                     const machine = machineBySlot.get(slot);
                     if (machine) {
                       return (
                         <MachineCell
                           key={key}
                           machine={machine}
                           onClick={() => onMachineClick(machine.machineId)}
                           isStale={isStale}
                         />
                       );
                     }

                    return (
                      <button
                        key={key}
                        type="button"
                        onClick={() => toast(`Missing machine: ${slot}`)}
                        className={cn(
                          'group relative flex h-[88px] flex-col items-start justify-between overflow-hidden',
                          'rounded-md border-2 border-dashed border-dark-border-inner bg-dark-surface p-3',
                          'hover:border-accent-dark hover:bg-dark-border-inner',
                          'dark:border-light-border-inner dark:bg-light-surface',
                          'dark:hover:border-accent-light dark:hover:bg-light-border-inner',
                          'transition-all duration-200',
                          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-dark dark:focus-visible:ring-accent-light'
                        )}
                        aria-label={`Missing machine ${slot}`}
                      >
                        <span className="font-mono text-base font-semibold text-dark-text-primary dark:text-light-text-primary">
                          {slot}
                        </span>
                        <span className="font-mono text-xs text-dark-text-secondary dark:text-light-text-secondary">
                          Missing
                        </span>
                      </button>
                    );
                  };

                  return row.map((slot, colIndex) => {
                    if (!slot) return renderEmpty(`tower-empty-${rowIndex}-${colIndex}`);
                    return renderMachineOrPlaceholder(slot, `tower-${slot}`);
                  });
                })}
              </div>
            </div>
          ) : (
            <MachineGrid machines={machines} onMachineClick={onMachineClick} isStale={isStale} />
          )}

          {/* Latest status change across machines */}
          <div className="pt-2 text-right font-mono text-xs text-dark-text-secondary dark:text-light-text-secondary">
            Latest change {timeAgo}
          </div>
        </CardContent>
      )}

      <CardContent className="flex justify-center pt-2">
        <button
          type="button"
          onClick={() => setIsExpanded(!isExpanded)}
          className="text-sm font-mono text-secondary hover:text-primary transition-colors duration-200"
          aria-expanded={isExpanded}
        >
          {isExpanded ? '↑ Hide details ↑' : '↓ View details ↓'}
        </button>
      </CardContent>
    </Card>
  );
}
