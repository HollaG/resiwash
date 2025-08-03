import {
  Accordion,
  AccordionControlProps,
  Button,
  Center,
  Checkbox,
  Collapse,
  Group,
  SimpleGrid,
  Space,
  Stack,
  Text,
} from "@mantine/core";
import { StatusIndicator } from "../mini/StatusIndicator";
import { useSavedLocations } from "../../hooks/useSavedLocations";
import { useEffect, useState } from "react";

import { useLocationInfo } from "../../hooks/query/useLocationInfo";
import classes from "./index.module.css";
import { MachineStatus } from "../../types/datatypes";
function AccordionControl(props: AccordionControlProps & { onClick: () => void, isChecked: boolean, isIndeterminate?: boolean }) {
  return (
    <Center>

      <Checkbox onChange={() => props.onClick()} checked={props.isChecked} indeterminate={props.isIndeterminate} />
      <div style={{ width: "8px" }} />
      <Accordion.Control {...props} onChange={() => { }} onClick={() => { }} />
    </Center>
  );
}

export const LocationSelector = () => {
  const { savedRoomsNumber, setSavedLocations, savedLocations } = useSavedLocations();
  const { data: availableLocations } = useLocationInfo();
  const [isEditing, setIsEditing] = useState(false);
  const [selectedRooms, setSelectedRooms] = useState<{ [areaId: number]: number[] }>({});

  const onSave = () => {
    setIsEditing(false);
    // write to localstorage

    setSavedLocations(selectedRooms);
  };

  const onCheck = (areaId: number, roomId: number) => {
    setSelectedRooms((prev) => {
      if (prev[areaId]) {
        if (prev[areaId].includes(roomId)) {
          return {
            ...prev,
            [areaId]: prev[areaId].filter((id) => id !== roomId),
          };
        } else {
          return {
            ...prev,
            [areaId]: [...(prev[areaId] || []), roomId],
          };
        }
      } else {
        return {
          ...prev,
          [areaId]: [roomId],
        };
      }
    });
  };

  useEffect(() => {
    console.log("selectedRooms updated:", selectedRooms);
  }, [selectedRooms]);
  const onCheckArea = (areaId: number) => {
    console.log("onCheckArea", areaId);
    setSelectedRooms((prev) => {
      console.log("previous selectedRooms", prev);
      if (prev[areaId]) {
        const newSelectedRooms = { ...prev };
        delete newSelectedRooms[areaId];
        return newSelectedRooms;
      } else {
        const allRoomIds = availableLocations?.find(location => location.areaId === areaId)?.rooms.map(room => room.roomId) || [];
        return {
          ...prev,
          [areaId]: allRoomIds,
        };
      }
    });
    console.log("new selectedRooms", selectedRooms);
  }

  useEffect(() => {
    setSelectedRooms(savedLocations);
  }, [savedLocations])

  return (
    <Stack>
      <Group gap={"xs"}>
        <StatusIndicator status={savedRoomsNumber > 0 ? MachineStatus.AVAILABLE : MachineStatus.IN_USE} />
        {savedRoomsNumber > 0
          ? `${savedRoomsNumber} saved rooms`
          : "No saved rooms"}
        <Space style={{ flexGrow: 1 }} />
        {isEditing ? (
          <Button onClick={onSave} variant="solid">
            {" "}
            Save{" "}
          </Button>
        ) : (
          <Button onClick={() => setIsEditing(true)}> Edit </Button>
        )}
      </Group>
      <Collapse in={isEditing}>
        {availableLocations?.map((location) => (
          <Accordion
            key={location.areaId}
            radius="md"
            defaultValue={`location-${location.areaId}`}
            variant="unstyled"

          >
            <Accordion.Item value={`location-${location.areaId}`}>
              <AccordionControl onClick={() => onCheckArea(location.areaId)}
                isChecked={selectedRooms[location.areaId]?.length === location.rooms.length}
                isIndeterminate={selectedRooms[location.areaId]?.length > 0 && selectedRooms[location.areaId]?.length < location.rooms.length}
              >{location.name}</AccordionControl>
              <Accordion.Panel>
                <SimpleGrid
                  cols={{
                    base: 1,
                    sm: 2,
                    md: 3,
                  }}
                >
                  {location.rooms.map((room, index) => (
                    <Checkbox.Card
                      key={index}
                      className={classes.root}
                      radius="lg"
                      onChange={() =>
                        onCheck(location.areaId, room.roomId)
                      }
                      checked={selectedRooms[location.areaId]?.includes(
                        room.roomId
                      )}
                    >
                      <Group wrap="nowrap" align="flex-start" >
                        <Checkbox.Indicator


                        />
                        <div>
                          <Text className={classes.label}>{room.name}</Text>
                          <Text className={classes.description}>
                            {room.machineCount} machines
                          </Text>
                        </div>
                      </Group>
                    </Checkbox.Card>
                  ))}
                  {location.rooms.length === 0 && (
                    <Text c="dimmed" >
                      No rooms available
                    </Text>
                  )}
                </SimpleGrid>
              </Accordion.Panel>
            </Accordion.Item>
          </Accordion>
        ))}
      </Collapse>
    </Stack>
  );
};
