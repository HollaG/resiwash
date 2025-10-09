import { Tabs as MantineTabs, Stack } from "@mantine/core"
import { useSavedLocations } from "../../hooks/useSavedLocations"
import { useLocationInfo } from "../../hooks/query/useLocationInfo"
import { useScrollableTabs } from "../Tabs/base/useScrollableTabs"

import classes from "./index.module.css"
import { useState } from "react"
import { DetailView } from "../saved-location/SavedLocation"

export const SavedLocationsWrapper = ({ debug = false }: { debug?: boolean }) => {
  const { savedLocations } = useSavedLocations()
  const { tabListReference } = useScrollableTabs();

  const [controlsRefs, setControlsRefs] = useState<Record<string, HTMLButtonElement | null>>({});
  const setControlRef = (val: string) => (node: HTMLButtonElement) => {
    controlsRefs[val] = node;
    setControlsRefs(controlsRefs);
  };

  // todo: localstorage
  const [value, setValue] = useState<string | null>('all');

  const flattened = Object.entries(savedLocations).map(([areaId, rooms]) => {
    return rooms.map((room) => ({
      areaId: Number(areaId),
      roomId: room,
    }))
  }).flat();
  const { data: locationData } = useLocationInfo()

  const getName = (areaId: number, roomId: number) => {
    const area = locationData?.find(location => location.areaId === areaId);
    const room = area?.rooms.find(room => room.roomId === roomId);
    return room ? `${area?.name} - ${room.name}` : `${area?.name} - Unknown Room`;
  }


  return <MantineTabs classNames={{ list: classes.list, tab: classes.tab }} defaultValue="all" value={value} onChange={setValue}>
    <MantineTabs.List ref={tabListReference}>
      <MantineTabs.Tab value="all" disabled={!flattened.length} ref={setControlRef("all")}>
        All Locations ({flattened.length})
      </MantineTabs.Tab>
      {flattened.map(({ areaId, roomId }) => (
        <MantineTabs.Tab key={`${areaId}-${roomId}`} value={`${areaId}-${roomId}`} ref={setControlRef(`${areaId}-${roomId}`)}>
          {getName(areaId, roomId)}
        </MantineTabs.Tab>
      ))}


    </MantineTabs.List>

    <MantineTabs.Panel value="all" p={8}>
      <Stack>

        {flattened.map(({ areaId, roomId }) => (

          <DetailView key={`${areaId}-${roomId}`} areaId={areaId} roomId={roomId} debug={debug} />

        ))}
      </Stack>

    </MantineTabs.Panel>
    {flattened.map(({ areaId, roomId }) => (
      <MantineTabs.Panel key={`${areaId}-${roomId}`} value={`${areaId}-${roomId}`} p={8}>
        <DetailView key={`${areaId}-${roomId}`} areaId={areaId} roomId={roomId} debug={debug} />
      </MantineTabs.Panel>
    ))}



  </MantineTabs>
  // <Tabs defaultValue="gallery">
  //   <Tabs.List>
  //     {/* <Tabs.Tab value="gallery" leftSection={<IconPhoto size={12} />}>
  //       Gallery
  //     </Tabs.Tab>
  //     <Tabs.Tab value="messages" leftSection={<IconMessageCircle size={12} />}>
  //       Messages
  //     </Tabs.Tab>
  //     <Tabs.Tab value="settings" leftSection={<IconSettings size={12} />}>
  //       Settings
  //     </Tabs.Tab> */}
  //     {flattened.map(({ areaId, roomId }) => (
  //       <Tabs.Tab key={`${areaId}-${roomId}`} value={`${areaId}-${roomId}`}>
  //         {getName(areaId, roomId)}
  //       </Tabs.Tab>
  //     ))}
  //   </Tabs.List>

  //   <Tabs.Panel value="gallery">
  //     Gallery tab content
  //   </Tabs.Panel>

  //   <Tabs.Panel value="messages">
  //     Messages tab content
  //   </Tabs.Panel>

  //   <Tabs.Panel value="settings">
  //     Settings tab content
  //   </Tabs.Panel>
  // </Tabs>
}