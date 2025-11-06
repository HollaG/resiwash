import {
  Accordion,
  Badge,
  Button,
  Checkbox,
  Collapse,
  Flex,
  Group,

  SimpleGrid,
  Stack,
  Text,
} from "@mantine/core";
import { useSavedLocations } from "../../hooks/useSavedLocations";
import { useEffect, useState } from "react";

import { useLocationInfo } from "../../hooks/query/useLocationInfo";
import classes from "./index.module.css";
// function AccordionControl(props: AccordionControlProps & { onClick: () => void, isChecked: boolean, isIndeterminate?: boolean }) {
//   return (
//     <Center>

//       <Checkbox onChange={() => props.onClick()} checked={props.isChecked} indeterminate={props.isIndeterminate} />
//       <div style={{ width: "8px" }} />
//       <Accordion.Control {...props} onChange={() => { }} onClick={() => { }} />
//     </Center>
//   );
// }

export const LocationSelector = () => {
  const { savedRoomsNumber, setSavedLocations, savedLocations } = useSavedLocations();
  const { data: availableLocations } = useLocationInfo();
  const [isEditing, setIsEditing] = useState(false);
  const [selectedRooms, setSelectedRooms] = useState<{ [areaId: number]: number[] }>({});

  const getMachineCount = (areaId: number) => {
    const area = availableLocations?.find(location => location.areaId === areaId);
    if (!area) return 0;
    return area.rooms.reduce((acc, room) => acc + (room.machineCount || 0), 0);
  }

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


  // const onCheckArea = (areaId: number) => {
  //   console.log("onCheckArea", areaId);
  //   setSelectedRooms((prev) => {
  //     console.log("previous selectedRooms", prev);
  //     if (prev[areaId]) {
  //       const newSelectedRooms = { ...prev };
  //       delete newSelectedRooms[areaId];
  //       console.log("newSelectedRooms", newSelectedRooms);
  //       return newSelectedRooms;
  //     } else {
  //       const allRoomIds = availableLocations?.find(location => location.areaId === areaId)?.rooms.map(room => room.roomId) || [];
  //       return {
  //         ...prev,
  //         [areaId]: allRoomIds,
  //       };
  //     }
  //   });
  //   console.log("new selectedRooms", selectedRooms, availableLocations);
  // }

  useEffect(() => {
    setSelectedRooms(savedLocations);
  }, [savedLocations])

  return (
    <Stack>
      <Group gap={"xs"} justify="end">
        {savedRoomsNumber > 0
          ? `${savedRoomsNumber} saved rooms`
          : <Badge color="red" size="sm" radius="sm">No saved rooms!</Badge>}
        {/* <Space style={{ flexGrow: 1 }} /> */}
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
              {/* <AccordionControl onClick={() => onCheckArea(location.areaId)}
                isChecked={selectedRooms[location.areaId]?.length === location.rooms.length}
                isIndeterminate={selectedRooms[location.areaId]?.length > 0 && selectedRooms[location.areaId]?.length < location.rooms.length}
              >{location.name}</AccordionControl> */}
              <Accordion.Control>
                <Flex align={'center'} gap={'8px'}>

                  <Text display={'inline-block'}>

                    {location.name}
                  </Text>

                  <Badge color="violet" variant="light" size="sm" radius='sm'>{location.rooms.length} rooms • {getMachineCount(location.areaId)} machines</Badge>
                </Flex>
              </Accordion.Control>
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
