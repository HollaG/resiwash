import { motion } from 'framer-motion';
import { useMemo } from 'react';
import { MachineStatusOverview } from '@/types/datatypes';
import { MachineCell } from './MachineCell';
import { containerVariants, itemVariants } from '@/lib/animations';
import { cn } from '@/lib/utils';
import { getMachineSlotNumber } from '@/utils/helpers';

interface MachineGridProps {
  machines: MachineStatusOverview[];
  onMachineClick: (machineId: number) => void;
  className?: string;
  isStale?: boolean;
}

export function MachineGrid({ machines, onMachineClick, className, isStale = false }: MachineGridProps) {
  const sortedMachines = useMemo(() => {
    const typeRank = (type: string) => {
      if (type === 'washer') return 0;
      if (type === 'dryer') return 1;
      return 2;
    };

    const compareByMachine = (a: MachineStatusOverview, b: MachineStatusOverview) => {
      const aNum = getMachineSlotNumber({ label: a.label, type: a.type, name: a.name });
      const bNum = getMachineSlotNumber({ label: b.label, type: b.type, name: b.name });

      if (aNum !== null && bNum !== null && aNum !== bNum) return aNum - bNum;

      return a.label.localeCompare(b.label);
    };

    return [...machines].sort((a, b) => {
      const typeDiff = typeRank(a.type) - typeRank(b.type);
      if (typeDiff !== 0) return typeDiff;
      return compareByMachine(a, b);
    });
  }, [machines]);

  return (
    <motion.div
      className={cn(
        'grid grid-cols-3 gap-2 sm:grid-cols-4 sm:gap-3 lg:grid-cols-5',
        className
      )}
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {sortedMachines.map((machine) => (
        <motion.div key={machine.machineId} variants={itemVariants}>
          <MachineCell
            machine={machine}
            onClick={() => onMachineClick(machine.machineId)}
            isStale={isStale}
          />
        </motion.div>
      ))}
    </motion.div>
  );
}
