import { formatDistanceToNow } from 'date-fns';
import { useEffect, useMemo, useState } from 'react';
import { MachineEvent, MachineStatus, MachineStatusOverview, convertMachineStatusToString } from '@/types/datatypes';
import { StatusBadge } from './StatusBadge';
import { CustomTimeline } from '../timeline/Timeline';
import { useMachineInfo } from '@/hooks/query/useMachineInfo';
import { shortMachineLabel } from '@/utils/helpers';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet';

interface MachineDetailSheetProps {
  machine: MachineStatusOverview | null;
  isOpen: boolean;
  onClose: () => void;
}

/**
 * MachineDetailSheet component shows detailed machine information in a bottom sheet
 * Uses Radix Dialog primitive for mobile bottom sheet
 * Content:
 * - Large status badge + label
 * - "Last changed: X mins ago"
 * - Timeline component (reused from existing)
 */
export function MachineDetailSheet({ machine, isOpen, onClose }: MachineDetailSheetProps) {
  const [displayMachine, setDisplayMachine] = useState<MachineStatusOverview | null>(machine);

  useEffect(() => {
    if (machine) setDisplayMachine(machine);
  }, [machine]);

  const { data: machineDetails, isLoading: isLoadingDetails } = useMachineInfo({
    roomId: displayMachine?.roomId ?? 0,
    machineId: displayMachine?.machineId ?? 0,
    load: isOpen && !!displayMachine,
  });

  const statusText = convertMachineStatusToString(
    displayMachine?.currentStatus ?? MachineStatus.UNKNOWN
  );

  const lastChanged = displayMachine?.lastChangeTime
    ? formatDistanceToNow(new Date(displayMachine.lastChangeTime), { addSuffix: true })
    : 'Unknown';

  const areaName = displayMachine?.room?.area?.name;
  const roomName = displayMachine?.room?.name;
  const locationLine = areaName && roomName
    ? `${areaName} - ${roomName}`
    : roomName || areaName || (displayMachine?.roomId ? `Room ${displayMachine.roomId}` : 'Unknown room');

  const timelineEvents = useMemo(() => {
    const raw = (machineDetails?.events ?? displayMachine?.events ?? []) as MachineEvent[];
    return [...raw].sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );
  }, [machineDetails?.events, displayMachine?.events]);

  if (!displayMachine) return null;

  return (
    <Sheet
      open={isOpen}
      onOpenChange={(open) => {
        if (!open) onClose();
      }}
    >
      <SheetContent className="max-h-[85vh] overflow-y-auto">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-3">
            <StatusBadge status={displayMachine.currentStatus} size="lg" />
            <span className="text-2xl font-bold">{shortMachineLabel(displayMachine.label, displayMachine.type, displayMachine.name)}</span>
          </SheetTitle>
          <SheetDescription className="text-left">{locationLine}</SheetDescription>
        </SheetHeader>

        <div className="mt-6 space-y-6">
          {/* Status information */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-dark-text-secondary dark:text-light-text-secondary">
                Current Status
              </span>
              <span className="text-base font-semibold text-dark-text-primary dark:text-light-text-primary">
                {statusText}
              </span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-dark-text-secondary dark:text-light-text-secondary">
                Last Changed
              </span>
              <span className="font-mono text-sm text-dark-text-primary dark:text-light-text-primary">
                {lastChanged}
              </span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-dark-text-secondary dark:text-light-text-secondary">
                Machine Type
              </span>
              <span className="text-sm capitalize text-dark-text-primary dark:text-light-text-primary">
                {displayMachine.type}
              </span>
            </div>
          </div>

          {/* Timeline section */}
          <div className="space-y-2">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-dark-text-primary dark:text-light-text-primary">
              Status History
            </h3>
            <div className="rounded-lg border border-dark-border bg-dark-bg p-4 dark:border-light-border dark:bg-light-bg">
              {isLoadingDetails ? (
                <div className="font-mono text-sm text-secondary">Loading history…</div>
              ) : (
                <CustomTimeline events={timelineEvents} />
              )}
            </div>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
