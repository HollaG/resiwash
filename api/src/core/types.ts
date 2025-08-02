// todo: change to UPPERCASE
export enum MachineType {
  UNKNOWN = "unknown",
  WASHER = "washer",
  DRYER = "dryer",
}

export enum MachineStatus {
  AVAILABLE = "AVAILABLE",
  IN_USE = "IN_USE",
  HAS_ISSUES = "HAS_ISSUES",
}

export const STATUS_CODE_MAP = {
  0: MachineStatus.AVAILABLE,
  1: MachineStatus.IN_USE,
};
