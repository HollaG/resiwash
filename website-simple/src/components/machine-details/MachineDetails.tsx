import { Card, Group, Box, Stack, Text, Collapse, } from "@mantine/core"
import { formatDistanceToNow } from "date-fns"
import { StatusIndicator } from "../mini/StatusIndicator"
import { MachineStatus, MachineStatusOverview } from "../../types/datatypes"
import { useState } from "react"
import { useMachineInfo } from "../../hooks/query/useMachineInfo"
import { getColorForMachineStatus } from "../../utils/colors"
import { CustomTimeline } from "../timeline/Timeline"

export const MachineDetails = ({
  machineOverview,
}: {
  machineOverview: MachineStatusOverview
}) => {

  const [showDetails, setShowDetails] = useState(false);

  const { data, isLoading } = useMachineInfo({
    areaId: machineOverview.room.area.areaId,
    roomId: machineOverview.room.roomId,
    machineId: machineOverview.machineId,
    load: showDetails, // Load details only when showDetails is true
  });

  return <Card padding="md" radius={'lg'} withBorder style={{ cursor: "pointer" }} onClick={() => setShowDetails((prev) => !prev)}>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>

      <Group style={{ flexWrap: 'nowrap' }} gap="md">
        <Box style={{ flexShrink: 0 }}>

          <StatusIndicator size="lg" status={(machineOverview.currentStatus)} />
        </Box>
        <Stack gap={'2px'}>
          <Text fw={600}>{machineOverview.name} </Text>
          <Text c="dimmed" size="sm"> Updated {machineOverview.lastUpdated ? formatDistanceToNow(new Date(machineOverview.lastUpdated), {
            addSuffix: true,
            includeSeconds: true,
            locale: undefined,
          }) : 'N/A'}</Text>
        </Stack>
      </Group>
      <Collapse in={showDetails}>
        <div style={{ marginTop: "32px" }}></div>

        {isLoading ? <Text> Loading... </Text> :
          <CustomTimeline events={data?.events || []} />

        }
      </Collapse>
    </div>
  </Card >
}

// const Indicator = ({ outside, inside }: { outside: MachineStatus, inside: MachineStatus }) => {
//   const innerColor = getColorForMachineStatus(inside);
//   const outerColor = getColorForMachineStatus(outside);



//   return <div style={{ display: 'flex', justifyContent: "center", alignItems: 'center', width: '16px', height: '16px', borderRadius: '50%', backgroundColor: outerColor }}>
//     <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: innerColor }}> </div>

//   </div>

// }

const VerticalBar = ({ status }: { status: MachineStatus }) => {
  const color = getColorForMachineStatus(status);
  return <div style={{
    width: '2px',
    height: '16px',
    backgroundColor: color,
  }}> </div>
}