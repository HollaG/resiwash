export type ServerResponse<T> = {
  status: string;
  data: T;
};

export type Area = {
  areaId: number;
  name: string;
  location: string | null;
  description: string | null;
  imageUrl: string | null;
  shortName: string | null;
  createdAt: string; // or Date
  updatedAt: string; // or Date
};

export type MachineEvent = {
  eventId: number;
  timestamp: string; // or `Date` if you parse it
  status: MachineStatus;

  // deprecated
  // use status instead
  statusCode: number;

  reading: number;
};

export type Machine = {
  machineId: number;
  name: string;
  label: string;
  type: MachineType; // Extend or narrow as needed
  imageUrl: string | null;
  createdAt: string; // or `Date`
  updatedAt: string; // or `Date`
  lastUpdated: string; // or `Date`
  lastChangeTime: string; // when the machine last changed status
};

export type Room = {
  roomId: number;
  name: string;
  location: string | null;
  description: string | null;
  imageUrl: string | null;
  shortName: string | null;
  createdAt: string; // or Date
  updatedAt: string; // or Date
};

// combined type
export type Location = Area & {
  rooms: (Room & { machineCount: number })[];
};

export type Sensor = {
  sensorId: number;
  macAddress: string;
  apiKey: string;
  createdAt: string; // or Date
  updatedAt: string; // or Date
};

export type SensorWithRoom = Sensor & {
  room: Room;
};

export type SensorToMachine = {
  sensorId: number;
  source: string;
  localId: number; // Local identifier for the sensor
  machineId: number; // ID of the machine this sensor is linked to
};

export type AreaWithRooms = Area & {
  rooms: Room[];
};

export type RoomWithMachines = Room & {
  machines: Machine[];
};

export type MachineWithEvents = Machine & {
  events: MachineEvent[];
  rawEvents: MachineEvent[]; // TODO: rename to RawEvent
};

export type RoomWithArea = Room & {
  area: Area;
};

export type MachineWithRoomAndEvents = Machine & {
  room: RoomWithArea;
  events: MachineEvent[];
};

// GET /${roomId}/${areaId} returns a list of machines in a room
// note: only return 1 event per machine to save bandwidth
export type MachineStatusOverview = {
  currentStatus: MachineStatus;
  previousStatus: MachineStatus;
  // machine: MachineWithRoomAndEvents;
} & MachineWithRoomAndEvents;


// GET /${roomId}/${areaId}/${machineId}
// returns 10 last events
export type MachineStatusSpecific = MachineWithRoomAndEvents

export enum MachineType {
  WASHER = "washer",
  DRYER = "dryer",
  OTHER = "other", // For any other types not specified
}

export enum MachineStatus {
  AVAILABLE = "AVAILABLE",
  IN_USE = "IN_USE",
  HAS_ISSUES = "HAS_ISSUES",
  UNKNOWN = "UNKNOWN", // For any status that doesn't fit the above
}

export const convertMachineStatusToString = (status: MachineStatus): string => {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return "Available";
    case MachineStatus.IN_USE:
      return "In Use";
    case MachineStatus.HAS_ISSUES:
      return "Has Issues";
    case MachineStatus.UNKNOWN:
      return "Unknown";
    default:
      return "Unknown Status";
  }
};

