import { MachineStatusOverview, MachineStatus, MachineType } from '@/types/datatypes';
import { getMachineSlotNumber } from '@/utils/helpers';
import { StatusBadge } from '@/components/machine/StatusBadge';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface MachineTypeStatusCardProps {
  title: string;
  machines: MachineStatusOverview[];
  icon: React.ReactNode;
  className?: string;
}

/**
 * MachineTypeStatusCard displays a compact status bar for a specific machine type
 * Shows individual machines as colored squares in physical order (W1, W2, W3...)
 * 
 * Layout:
 * ┌─────────────────────────────────────┐
 * │ 🧺 Washers                          │
 * │                                     │
 * │ [🟩][🟦][🟩][🟩][🟦][🟩][🟩][🟩]  │
 * │                              5 / 8  │
 * └─────────────────────────────────────┘
 */
export function MachineTypeStatusCard({
  title,
  machines,
  icon,
  className,
}: MachineTypeStatusCardProps) {
  // Sort machines by W/D slot number when possible.
  const sortedMachines = [...machines].sort((a, b) => {
    const aNum = getMachineSlotNumber({ label: a.label, type: a.type, name: a.name });
    const bNum = getMachineSlotNumber({ label: b.label, type: b.type, name: b.name });

    if (aNum !== null && bNum !== null && aNum !== bNum) return aNum - bNum;

    return a.label.localeCompare(b.label);
  });

  const availableCount = machines.filter(
    (m) => m.currentStatus === MachineStatus.AVAILABLE
  ).length;
  const totalCount = machines.length;

  return (
    <Card className={cn('overflow-hidden', className)}>
      <CardContent className="p-4 space-y-3">
        {/* Header with icon and title */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {icon}
            <h3 className="text-lg font-bold uppercase tracking-tight text-primary">
              {title}
            </h3>
          </div>
        </div>

        {/* Status bar - individual machine indicators */}
        {sortedMachines.length > 0 ? (
          <div className="flex flex-wrap gap-1.5">
            {sortedMachines.map((machine) => (
              <StatusBadge
                key={machine.machineId}
                status={machine.currentStatus}
                size="md"
                className="transition-transform hover:scale-110"
                aria-label={`${machine.label}: ${machine.currentStatus}`}
              />
            ))}
          </div>
        ) : (
          <div className="text-sm text-secondary font-mono">
            No machines
          </div>
        )}

        {/* Count summary */}
        <div className="flex justify-end">
          <div className="text-xl font-bold font-mono text-primary">
            {availableCount} / {totalCount}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

/**
 * MachineTypeStatusRow - Displays washers and dryers side by side
 * Used in the home header to show status overview
 */
interface MachineTypeStatusRowProps {
  machines: MachineStatusOverview[];
  className?: string;
}

export function MachineTypeStatusRow({
  machines,
  className,
}: MachineTypeStatusRowProps) {
  // Separate washers and dryers
  const washers = machines.filter((m) => m.type === MachineType.WASHER);
  const dryers = machines.filter((m) => m.type === MachineType.DRYER);

  // Washer icon (simple SVG)
  const washerIcon = (
    <svg
      className="w-5 h-5 text-primary"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <rect x="4" y="4" width="16" height="16" rx="2" strokeWidth="2" />
      <circle cx="12" cy="13" r="4" strokeWidth="2" />
      <circle cx="8" cy="7" r="1" fill="currentColor" />
      <circle cx="11" cy="7" r="1" fill="currentColor" />
    </svg>
  );

  // Dryer icon (simple SVG)
  const dryerIcon = (
    <svg
      className="w-5 h-5 text-primary"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <rect x="4" y="4" width="16" height="16" rx="2" strokeWidth="2" />
      <circle cx="12" cy="13" r="4" strokeWidth="2" />
      <path d="M8 7h8" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );

  return (
    <div className={cn('grid grid-cols-1 md:grid-cols-2 gap-4', className)}>
      <MachineTypeStatusCard
        title="Washers"
        machines={washers}
        icon={washerIcon}
      />
      <MachineTypeStatusCard
        title="Dryers"
        machines={dryers}
        icon={dryerIcon}
      />
    </div>
  );
}
