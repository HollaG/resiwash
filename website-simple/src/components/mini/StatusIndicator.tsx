import { Box } from '@mantine/core';
import { MachineStatus } from '../../types/datatypes';

interface StatusIndicatorProps {
  /** The status of the indicator */
  status: MachineStatus;
  /** Size variant of the indicator */
  size?: 'sm' | 'md' | 'lg';
}

/**
 * A circular status indicator that shows different states with appropriate colors
 */
export const StatusIndicator = ({ status, size = 'md' }: StatusIndicatorProps) => {
  const getBackgroundColor = () => {
    switch (status) {
      case MachineStatus.AVAILABLE:
        return 'var(--mantine-color-green-5)';
      case MachineStatus.IN_USE:
        return 'var(--mantine-color-red-5)';
      case MachineStatus.UNKNOWN:
        return 'var(--mantine-color-gray-5)';
      default:
        return 'var(--mantine-color-gray-5)';
    }
  };

  const getSizeStyles = () => {
    switch (size) {
      case 'sm':
        return { width: 12, height: 12, borderRadius: '4px' };
      case 'md':
        return { width: 16, height: 16, borderRadius: '4px' };
      case 'lg':
        return { width: 20, height: 20, borderRadius: '6px' };
      default:
        return { width: 16, height: 16, borderRadius: '4px' };
    }
  };

  return (
    <Box
      style={{
        ...getSizeStyles(),
        backgroundColor: getBackgroundColor(),
      }}
    />
  );
};