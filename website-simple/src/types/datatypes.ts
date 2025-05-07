export type ServerResponse<T> = {
  status: number,
  data: T
}

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
  status: string | null;
  statusCode: number;
};

export type Machine = {
  machineId: number;
  name: string;
  label: string;
  type: 'washer' | 'dryer' | string; // Extend or narrow as needed
  imageUrl: string | null;
  createdAt: string; // or `Date`
  updatedAt: string; // or `Date`
  lastUpdated: string; // or `Date`
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

// GET /${roomId}/${areaId}
export type MachineStatusOverview = {
  status: number, // TODO: change to enum
  machine: MachineWithRoomAndEvents
}

// GET /${roomId}/${areaId}/${machineId}
export type MachineStatusSpecific = {
  status: number,
  machine: MachineWithEvents
}