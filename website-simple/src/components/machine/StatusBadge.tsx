import { cva, type VariantProps } from 'class-variance-authority';
import { motion } from 'framer-motion';
import { MachineStatus, convertMachineStatusToString } from '@/types/datatypes';
import { cn } from '@/lib/utils';

const statusVariants = cva('box-border rounded-sm', {
  variants: {
    status: {
      [MachineStatus.AVAILABLE]: 'bg-status-available',
      [MachineStatus.IN_USE]: 'bg-status-inUse',
      [MachineStatus.FINISHING]: 'bg-transparent border-2 border-dashed border-status-finishing',
      [MachineStatus.HAS_ISSUES]: 'bg-status-issues',
      [MachineStatus.UNKNOWN]: 'bg-status-unknown',
    },
    size: {
      sm: 'w-3 h-3',
      md: 'w-4 h-4',
      lg: 'w-5 h-5',
    },
  },
  defaultVariants: {
    status: MachineStatus.UNKNOWN,
    size: 'md',
  },
});

interface StatusBadgeProps extends VariantProps<typeof statusVariants> {
  status: MachineStatus;
  showPulse?: boolean;
  className?: string;
}

/**
 * StatusBadge component displays a colored square indicator for machine status
 * Replaces the old StatusIndicator component with a more brutalist design
 */
export function StatusBadge({ status, size, showPulse = false, className }: StatusBadgeProps) {
  const statusText = convertMachineStatusToString(status);

  const Component = showPulse ? motion.div : 'div';
  const animationProps = showPulse
    ? {
        initial: { scale: 1 },
        animate: { scale: [1, 1.2, 1] },
        transition: { duration: 0.6 },
      }
    : {};

  return (
    <Component
      className={cn(statusVariants({ status, size }), className)}
      aria-label={`Machine status: ${statusText}`}
      role="status"
      {...animationProps}
    />
  );
}
