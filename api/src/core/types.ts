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

export const getReadableMachineStatus = (status: MachineStatus): string => {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return "Available";
    case MachineStatus.IN_USE:
      return "In Use";
    case MachineStatus.FINISHING:
      return "Finishing";
    case MachineStatus.HAS_ISSUES:
      return "Has Issues";
    case MachineStatus.UNKNOWN:
      return "Unknown";
  }
};

export const STATUS_CODE_MAP = {
  0: MachineStatus.AVAILABLE,
  1: MachineStatus.IN_USE,
  2: MachineStatus.FINISHING,
  3: MachineStatus.HAS_ISSUES,
  4: MachineStatus.UNKNOWN,
};

export class GetQueryBoolean {
  static FALSE = "false";
  static TRUE = "true";
  static parse(value: any): boolean | undefined {
    if (value === undefined || value === null) {
      return undefined;
    }
    if (typeof value === "boolean") {
      return value;
    }
    if (typeof value === "string") {
      const val = value.toLowerCase();
      if (val === "true" || val === "1") {
        return true;
      }
      if (val === "false" || val === "0") {
        return false;
      }
    }
    return undefined;
  }
}
