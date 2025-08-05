import { MachineStatus } from "../types/datatypes";

export const getColorForMachineStatus = (status: MachineStatus): string => {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return "var(--mantine-color-green-5)";
    case MachineStatus.IN_USE:
      return "var(--mantine-color-red-5)";

    case MachineStatus.HAS_ISSUES:
      return "var(--mantine-color-black)"; // TODO:

    case MachineStatus.UNKNOWN:
      return "var(--mantine-color-gray-5)";

    default:
      return "var(--mantine-color-gray-5)"; // Fallback color
  }
}