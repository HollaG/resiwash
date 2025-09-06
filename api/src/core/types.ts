// todo: change to UPPERCASE
export enum MachineType {
  UNKNOWN = "unknown",
  WASHER = "washer",
  DRYER = "dryer",
}

export enum MachineStatus {
  AVAILABLE = "AVAILABLE",
  IN_USE = "IN_USE",
  FINISHING = "FINISHING",
  HAS_ISSUES = "HAS_ISSUES",
  UNKNOWN = "UNKNOWN",
}

export const STATUS_CODE_MAP = {
  0: MachineStatus.AVAILABLE,
  1: MachineStatus.IN_USE,
  2: MachineStatus.FINISHING,
  3: MachineStatus.HAS_ISSUES,
  4: MachineStatus.UNKNOWN,
};
