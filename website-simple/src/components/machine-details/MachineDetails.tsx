import { Card, Group, Box, Stack, Text, Collapse, } from "@mantine/core"
import { formatDistanceToNow } from "date-fns"
import { StatusIndicator } from "../mini/StatusIndicator"
import { MachineStatusOverview } from "../../types/datatypes"
import { useState } from "react"
import { useMachineInfo } from "../../hooks/query/useMachineInfo"
import { CustomTimeline } from "../timeline/Timeline"

export const MachineDetails = ({
  machineOverview,
}: {
  machineOverview: MachineStatusOverview
}) => {

  const [showDetails, setShowDetails] = useState(false);

  const { data, isLoading } = useMachineInfo({
    roomId: machineOverview.roomId,
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
