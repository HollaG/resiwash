import { Group, Stack, Text } from "@mantine/core";
import { useLocationMachines } from "../../hooks/query/useLocationMachines";
import { useLocationInfo } from "../../hooks/query/useLocationInfo";
import React from "react";
import { StatusIndicator } from "../mini/StatusIndicator";
import { MachineStatus } from "../../types/datatypes";
import { MachineDetails } from "../machine-details/MachineDetails";

type DetailViewProps = {
  areaId: number;
  roomId: number;
}
const SavedLocation = (props: DetailViewProps) => {
  const { areaId, roomId } = props;

  const { data: machineData, isLoading } = useLocationMachines({ areaId, roomId });
  const { data: locationData } = useLocationInfo()

  const area = locationData?.find(location => location.areaId === areaId);
  const room = area?.rooms.find(r => r.roomId === roomId);

  console.log({ machineData, area, room })

  if (isLoading || !machineData) {
    return <div>Loading...</div>;
  }

  const MachineStatusGroup = machineData.map((machineOverview, index) => {
    const status = (machineOverview.currentStatus);

    return <StatusIndicator status={status} key={index} />
  })

  const availableMachines = (machineData.filter(machine => (machine.currentStatus) === MachineStatus.AVAILABLE).length) || 0;

  return <Stack>
    <Group px={'lg'}>
      <Text fw={700} size="xl">  {room?.name} </Text>
      <div style={{ flexGrow: 1 }} />
      <Group gap="4px">
        {MachineStatusGroup}
      </Group>
      {availableMachines.toString()} / {machineData.length.toString()}
    </Group>

    <Stack gap="sm">
      {machineData.map((machineOverview, index) => (
        <MachineDetails key={index} machineOverview={machineOverview} />

      ))}
    </Stack>

  </Stack>
  // <div>
  //   <h1>{area.name} - {room.name}</h1>
  //   <p>{area.description}</p>
  //   <img src={area.imageUrl || '/default-area-image.png'} alt={area.name} />
  //   <p>Room Description: {room.description}</p>
  //   <img src={room.imageUrl || '/default-room-image.png'} alt={room.name} />
  // </div>

};

export const DetailView = React.memo(SavedLocation);