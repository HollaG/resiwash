export enum MachineType {
  UNKNOWN = "UNKNOWN",
  WASHER = "WASHER",
  DRYER = "DRYER",
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
