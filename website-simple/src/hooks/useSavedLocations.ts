import { useLocalStorage } from "@mantine/hooks";

type SavedLocation = {
  [areaId: number]: number[]; // Maps areaId to an array of room names
};

export const useSavedLocations = () => {
  const [savedLocations, setSavedLocations] = useLocalStorage<SavedLocation>({
    key: "savedLocations",
    defaultValue: {},
  });
  // convert all saved locations to numbers

  const addRoomToSavedLocation = (areaId: number, roomId: number) => {
    setSavedLocations((prev) => {
      const rooms = prev[areaId] || [];
      return {
        ...prev,
        [areaId]: [...rooms, roomId],
      };
    });
  };

  const savedAreasNumber = Object.keys(savedLocations).length;
  const savedRoomsNumber = Object.values(savedLocations).reduce(
    (acc, rooms) => acc + rooms.length,
    0
  );
  const hasNoSavedLocations = savedRoomsNumber === 0;

  return {
    savedLocations,
    addRoomToSavedLocation,
    hasNoSavedLocations,
    savedAreasNumber,
    savedRoomsNumber,
    setSavedLocations,
  };
};
