export enum MachineType {
  UNKNOWN = "unknown",
  WASHER = "washer",
  DRYER = "dryer",
}

export enum MachineStatus { 
  AVAILABLE = "available",
  IN_USE = "in_use",
  HAS_ISSUES = "has_issues",
}

export const STATUS_CODE_MAP = {
  0: MachineStatus.AVAILABLE,
  1: MachineStatus.IN_USE,
}