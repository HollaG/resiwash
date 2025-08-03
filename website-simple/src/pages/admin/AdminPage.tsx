import { Area, Machine, MachineWithEvents, Room, Sensor, SensorToMachine, SensorWithRoom } from "../../types/datatypes";
import { Box, Button, Group, Select, Stack, TextInput } from "@mantine/core";
import { useFetchData } from "../../hooks/useFetchData";
import { CustomTable } from "../../components/CustomTable";
import { useCrud } from "../../hooks/useCRUD";
import { useState } from "react";
import { useAuth } from "../../context/useAuth";

const getAreasUrl = () => {
  return '/areas';
}

const getRoomsUrl = (areaId: number) => {
  return `/areas/${areaId}`;
}

const getMachinesUrl = (areaId: number, roomId: number) => {
  return `/areas/${areaId}/${roomId}`;
}

const getSensorsUrl = () => {
  return '/sensors'
}

const getSensorToMachineUrl = (sensorId: number) => {
  return `/sensors/link/${sensorId}`;
}

export const AdminPage = () => {


  const { data: areaData, refetch } = useFetchData<Area[]>(getAreasUrl());
  const { crudData: crudAreaData } = useCrud<Area>(
    getAreasUrl(),
  )





  const { currentUser, login: loginUser, logout } = useAuth();
  const login = () => {
    const email = window.prompt("Enter email:");
    if (!email) return;
    const password = window.prompt("Enter password:");
    if (!password) return;

    // You can now use username and password, e.g., send to your API
    console.log("Username:", email, "Password:", password);

    loginUser(email, password)
      .then(() => {
        console.log("User logged in successfully");
      })
      .catch((error: any) => {
        console.error("Error logging user:", error);
      });
  };

  const headerKeysArea: {
    value: keyof Area;
    label: string;
  }[] = [
      { value: 'areaId', label: 'Area ID' },
      { value: 'name', label: 'Name' },
    ]


  const onAddArea = async (newArea: Area) => {
    console.log('Adding new area:', newArea);

    try {
      const data = await crudAreaData({
        method: "POST",
        body: newArea,
      });
      console.log('Area added:', data);
      refetch();
      return data;
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  const onDeleteArea = async (area: Area) => {
    console.log('Deleting area:', area);
    try {
      const data = await crudAreaData({
        method: "DELETE",
        body: {},
        append: area.areaId.toString(),
      });
      console.log('Area deleted:', data);
      refetch();
      return data;
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  const areasAsOptions = areaData?.map(area => ({
    value: area.areaId.toString(),
    label: area.name,
  })) || [];

  const [selectedAreaId, setSelectedAreaId] = useState<number | null>(null);

  const onClickArea = (area: Area) => {
    console.log('Selected area:', area);
    setSelectedAreaId(area.areaId);
    setSelectedRoomId(null); // Reset selected room when area changes
  }


  const { data: roomData, refetch: refetchRooms } = useFetchData<Room[]>(getRoomsUrl(selectedAreaId || 0));
  const { crudData: crudRoomData } = useCrud<Room>(
    getRoomsUrl(selectedAreaId || 0),
  )


  const headerKeysRoom: {
    value: keyof Room;
    label: string;
  }[] = [
      { value: 'roomId', label: 'Room ID' },
      { value: 'name', label: 'Name' },
    ]

  const onAddRoom = async (newRoom: Room) => {
    console.log('Adding new room:', newRoom);

    try {
      const data = await crudRoomData({
        method: "POST",
        body: newRoom,
      });
      console.log('Room added:', data);
      refetchRooms();

      return data
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  const onDeleteRoom = async (room: Room) => {
    if (!selectedAreaId) {
      console.error('No area selected for room deletion');
      return Promise.reject({
        error: 'No area selected for room deletion'
      })
    }
    console.log('Deleting room:', room);
    try {
      const data = await crudRoomData({
        method: "DELETE",
        body: {},
        append: room.roomId.toString(),
      });
      console.log('Room deleted:', data);
      refetchRooms();
    } catch (message) {
      return console.error(message);
    }
  }

  const [selectedRoomId, setSelectedRoomId] = useState<number | null>(null);
  const roomsAsOptions = roomData?.map(room => ({
    value: room.roomId.toString(),
    label: room.name,
  })) || [];

  const onClickRoom = (room: Room) => {
    console.log('Selected room:', room);
    setSelectedRoomId(room.roomId);
  }

  const { crudData: crudMachineData, } = useCrud<Room>(
    getMachinesUrl(selectedAreaId || 0, selectedRoomId || 0),
  )

  const headerKeysMachine: {
    value: string;
    // value: keyof Machine;
    label: string;
    required?: boolean;
  }[] = [
      { value: 'machine.machineId', label: 'Machine ID' },
      { value: 'machine.name', label: 'Name', required: true },
      { value: 'machine.type', label: 'Type', required: true },
      { value: 'machine.label', label: 'Label', required: true },
    ]

  const onAddMachine = async (newMachine: Machine) => {
    console.log('Adding new machine:', newMachine);
    try {
      const data = await crudMachineData({
        method: "POST",
        body: newMachine,
      });
      console.log('Machine added:', data);
      return data
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  const onDeleteMachine = async (machine: Machine) => {
    if (!selectedAreaId || !selectedRoomId) {
      console.error('No area or room selected for machine deletion');
      return {
        error: 'No area or room selected for machine deletion'

      }
    }
    console.log('Deleting machine:', machine);
    try {
      const data = await crudMachineData({
        method: "DELETE",
        body: {},

        // TODO: LOOK INTO THE TYPING ISSUE ()
        // @ts-ignore
        append: machine.machine.machineId.toString(),
      });
      console.log('Machine deleted:', data);

      return data;
    } catch (message) {
      return console.error(message);
    }
  }

  const { crudData: sensorCrud } = useCrud<Sensor>(getSensorsUrl());

  /**
   * Special - doesn't come from table
   * @param e 
   */
  const onSensorUpdate = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const sensorId = formData.get('sensorId')?.toString();
    const roomId = formData.get('roomId')?.toString();
    const apiKey = formData.get('apiKey')?.toString();



    sensorCrud({
      body: {
        sensorId: sensorId ? parseInt(sensorId) : null,
        roomId: roomId ? parseInt(roomId) : null,
        apiKey: apiKey || null,
      },
      method: "POST",
      append: sensorId ? sensorId.toString() : '',
    })

  }

  const [selectedSensorId, setSelectedSensorId] = useState<number | null>(null);
  const { data: sensorData, } = useFetchData<SensorWithRoom[]>(getSensorsUrl());
  const sensorsAsOptions = sensorData?.map(sensor => ({
    value: sensor.sensorId.toString(),
    label: sensor.sensorId.toString(),
  })) || [];

  const onClickSensor = (sensor: SensorWithRoom) => {
    console.log('Selected sensor:', sensor);
    setSelectedSensorId(sensor.sensorId);
  }

  const { crudData: sensorToMachineCrud } = useCrud<SensorToMachine>(getSensorToMachineUrl(selectedSensorId || -1));

  const onAddSensorToMachine = async (newSensorToMachine: SensorToMachine) => {
    console.log('Adding new sensor to machine:', newSensorToMachine);
    try {
      const data = await sensorToMachineCrud({
        method: "POST",
        body: newSensorToMachine,
      });
      console.log('Sensor to machine added:', data);

      return data
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  const onDeleteSensorToMachine = async (sensorToMachine: SensorToMachine) => {
    console.log('Deleting sensor to machine:', sensorToMachine);
    try {
      const data = await sensorToMachineCrud({
        method: "DELETE",
        body: {
          source: sensorToMachine.source,
          localId: sensorToMachine.localId,
          machineId: sensorToMachine.machineId,

        },
      });
      console.log('Sensor to machine deleted:', data);

      return data
    } catch (message_1) {
      return console.error(message_1);
    }
  }

  if (!currentUser) {
    return <Stack style={{ paddingBottom: "2rem" }}>
      <Button onClick={login}>Login</Button>
    </Stack>
  }

  return <Stack style={{ paddingBottom: "2rem" }}>

    {currentUser && <Box>
      <b>Logged in as {currentUser.email}</b>
      <Button onClick={() => {
        logout();
      }}>Logout</Button>
    </Box>}
    <h1>Areas</h1>
    <CustomTable<Area> headerKeys={headerKeysArea} url={getAreasUrl()} onAdd={onAddArea} onDelete={onDeleteArea} onRowClick={onClickArea} />

    <h1>Rooms</h1>
    <Select
      label="Areas"
      placeholder="Pick value"
      data={areasAsOptions}
      onChange={(value) => {
        setSelectedAreaId(value ? parseInt(value) : null);

      }}

      value={selectedAreaId?.toString() || ""}
    />

    <CustomTable<Room> url={getRoomsUrl(selectedAreaId || -1)} headerKeys={headerKeysRoom} onAdd={onAddRoom} onDelete={onDeleteRoom} onRowClick={onClickRoom} />

    <h1>Machines</h1>
    <Select
      label="Rooms"
      placeholder="Pick value"
      data={roomsAsOptions}
      onChange={(value) => {
        setSelectedRoomId(value ? parseInt(value) : null);

      }}

      value={selectedRoomId?.toString() || ""}
    />

    <CustomTable<MachineWithEvents> url={getMachinesUrl(selectedAreaId || -1, selectedRoomId || -1)} headerKeys={headerKeysMachine} onAdd={onAddMachine} onDelete={onDeleteMachine} />

    <h1>Sensors</h1>
    <CustomTable<SensorWithRoom> url={getSensorsUrl()} headerKeys={[
      { value: 'sensorId', label: 'ID' },
      { value: 'macAddress', label: 'MAC Address' },
      { value: 'apiKey', label: 'API Key' },
      { value: 'room.roomId', label: 'Room ID' },
    ]} onRowClick={onClickSensor} />

    <form onSubmit={onSensorUpdate}>
      <Group>
        <TextInput label="Sensor ID" name="sensorId" required />
        <TextInput label="Room ID" name="roomId" required />
        <TextInput label="apiKey" name="apiKey" />
        <Button type="submit" variant="outline" color="blue">Update Sensor</Button>
      </Group>

    </form>

    <h1>Link Sensors to Machines</h1>
    <Select
      label="Sensor ID to link"
      placeholder="Pick value"
      data={sensorsAsOptions}

      onChange={(value) => {
        setSelectedSensorId(value ? parseInt(value) : null);

      }}

      value={selectedSensorId?.toString() || ""}
    />
    <CustomTable<SensorToMachine> url={getSensorToMachineUrl(selectedSensorId || -1)} headerKeys={[
      // { value: 'sensorId', label: 'ID' },
      { value: 'source', label: 'Source' },
      { value: 'localId', label: 'Local ID' },
      { value: 'machineId', label: 'Machine ID' },
    ]}
      onAdd={onAddSensorToMachine}
      onDelete={onDeleteSensorToMachine}
    />




  </Stack>
}