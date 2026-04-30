import { MachineStatus } from "../types/datatypes";

export const getColorForMachineStatus = (status: MachineStatus): string => {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return "var(--mantine-color-green-5)";
    case MachineStatus.IN_USE:
      return "var(--mantine-color-yellow-5)";

    case MachineStatus.HAS_ISSUES:
      return "var(--mantine-color-black)"; // TODO:

    case MachineStatus.UNKNOWN:
      return "var(--mantine-color-gray-5)";
    case MachineStatus.FINISHING:
      return "var(--mantine-color-yellow-5)";
    case MachineStatus.FINISHED:
      return "var(--mantine-color-green-5)";

    default:
      return "var(--mantine-color-gray-5)"; // Fallback color
  }
};

export const getTextColorForMachineStatus = (status: MachineStatus): string => {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return "var(--mantine-color-green-9)";
    case MachineStatus.IN_USE:
      return "var(--mantine-color-yellow-9)";
    case MachineStatus.HAS_ISSUES:
      return "var(--mantine-color-black)"; // TODO:
    case MachineStatus.UNKNOWN:
      return "var(--mantine-color-gray-9)";
    case MachineStatus.FINISHING:
      return "var(--mantine-color-yellow-9)";
    case MachineStatus.FINISHED:
      return "var(--mantine-color-green-9)";
    default:
      return "var(--mantine-color-gray-9)"; // Fallback color
  }
};

/**
 * Get styles for machine status
 * Included:
 *   backgroundColor
 *   borderColor
 *   borderStyle
 *
 * If a machine is finishing, it is the IN_USE style, but with a dashed border and no infill.
 * @param status
 */
export const getStylesForMachineStatus = (
  status: MachineStatus,
): Record<string, string> => {
  const baseStyles: Record<string, string> = {
    backgroundColor: "transparent",
  };

  if (status === MachineStatus.FINISHING) {
    baseStyles.borderStyle = "dashed";
    baseStyles.borderWidth = "3px";
    baseStyles.borderColor = getColorForMachineStatus(MachineStatus.IN_USE);

    return baseStyles;
  }

  if (status === MachineStatus.FINISHED) {
    baseStyles.borderStyle = "dashed";
    baseStyles.borderWidth = "3px";
    baseStyles.borderColor = getColorForMachineStatus(MachineStatus.AVAILABLE);

    return baseStyles;
  }

  baseStyles.backgroundColor = getColorForMachineStatus(status);

  return baseStyles;
};
