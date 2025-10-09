import { Card, Group, Box, Stack, Text, Collapse } from "@mantine/core";
import { formatDistanceToNow } from "date-fns";
import { StatusIndicator } from "../mini/StatusIndicator";
import { MachineStatusOverview } from "../../types/datatypes";
import { useMemo, useState } from "react";
import { useMachineInfo } from "../../hooks/query/useMachineInfo";
import { CustomTimeline } from "../timeline/Timeline";
import { useEventInfo } from "../../hooks/query/useEventInfo";
import uPlot from "uplot";
import UplotReact from "uplot-react";
import "uplot/dist/uPlot.min.css";
import { useAuth } from "../../context/useAuth";

export const MachineDetails = ({
  machineOverview,
  debug = false,
}: {
  machineOverview: MachineStatusOverview;
  debug?: boolean;
}) => {
  const isSignedIn = useAuth().currentUser !== null;
  const [showDetails, setShowDetails] = useState(false);

  const { data, isLoading } = useMachineInfo({
    roomId: machineOverview.roomId,
    machineId: machineOverview.machineId,
    load: showDetails, // Load details only when showDetails is true
  });

  const { data: eventData, isLoading: eventLoading } = useEventInfo({
    machineId: machineOverview.machineId,
    raw: debug,
    load: showDetails && isSignedIn, // Load details only when showDetails is true
  });

  const options: uPlot.Options = useMemo(
    () => ({
      title: machineOverview.name,

      width: 800,
      height: 600,

      series: [
        {},
        ...(eventData?.series.map((label, index) => ({
          show: true,

          spanGaps: false,
          label,
          stroke: eventData.series[index].toLowerCase().includes("threshold")
            ? "blue"
            : "red",
          width: 1,
          // fill: "rgba(255, 0, 0, 0.3)",
          dash: [10, 5],
        })) || []),
      ],
    }),
    [machineOverview.machineId, eventData?.series]
  );

  return (
    <Card padding="md" radius={"lg"} withBorder style={{ cursor: "pointer" }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
        <Group
          style={{ flexWrap: "nowrap" }}
          gap="md"
          onClick={() => setShowDetails((prev) => !prev)}
        >
          <Box style={{ flexShrink: 0 }}>
            <StatusIndicator size="lg" status={machineOverview.currentStatus} />
          </Box>
          <Stack gap={"2px"}>
            <Text fw={600}>{machineOverview.name} </Text>
            <Text c="dimmed" size="sm">
              {" "}
              Updated{" "}
              {machineOverview.lastUpdated
                ? formatDistanceToNow(new Date(machineOverview.lastUpdated), {
                  addSuffix: true,
                  includeSeconds: true,
                  locale: undefined,
                })
                : "N/A"}
            </Text>
          </Stack>
        </Group>
        <Collapse in={showDetails}>
          <div style={{ marginTop: "32px" }}></div>

          {isLoading ? (
            <Text> Loading... </Text>
          ) : (
            <CustomTimeline events={data?.events || []} />
          )}
          {isSignedIn ? (
            eventLoading ? (
              <Text> Loading Events... </Text>
            ) : (
              <Box mt="md">
                <Text fw={600} mb="xs">
                  {" "}
                  Recent Events{" "}
                </Text>
                <UplotReact options={options} data={eventData?.points || []} />
              </Box>
            )
          ) : null}
        </Collapse>
      </div>
    </Card>
  );
};
