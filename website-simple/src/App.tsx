// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { Anchor, Box, Button, Container, Divider, MantineProvider, Stack, Table } from '@mantine/core';
import { useEffect, useState } from 'react';
import { useFetch } from '@mantine/hooks';
import { statusCodeToEnum } from './types/enums';
import { MachineStatusOverview, MachineStatusSpecific, MachineWithEvents, ServerResponse } from './types/datatypes';
import { formatDate, formatDistanceToNow } from 'date-fns';



export default function App() {
  const [washerCount, setWasherCount] = useState(0);
  const [dryerCount, setDryerCount] = useState(0);

  const [areaId] = useState(2);
  const [roomId] = useState(1);

  const [url] = useState("https://resiwash.marcussoh.com/api/v1")

  const [currentMachine, setCurrentMachine] = useState<MachineWithEvents | null>(null)

  const { data, refetch } = useFetch<ServerResponse<MachineStatusOverview[]>>(
    `${url}/areas/${areaId}/${roomId}`
  )

  useEffect(() => {
    if (data) {
      setWasherCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'washer').length);
      setDryerCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'dryer').length);
    }
  }, [data])

  const rows = ((data?.data) || []).map((machineStatus) => (
    <Table.Tr key={machineStatus.machine.machineId} onClick={() => onTableRowClicked(machineStatus.machine.machineId)} style={{ cursor: "pointer" }}>
      <Table.Td>{statusCodeToEnum(machineStatus.status)}</Table.Td>
      <Table.Td>{machineStatus.machine.room.name}</Table.Td>
      <Table.Td>{machineStatus.machine.name}</Table.Td>
      <Table.Td>{machineStatus.machine.type}</Table.Td>
      <Table.Td>{machineStatus.machine.lastUpdated ? formatDistanceToNow(new Date(machineStatus.machine.lastUpdated), {
        addSuffix: true,
        includeSeconds: true,
        locale: undefined,
      }) : "No data received for this machine"}</Table.Td>
    </Table.Tr>
  ));

  const onTableRowClicked = (machineId: number) => {
    // setCurrentMachineId(machine.machineId)

    fetch(`${url}/areas/${areaId}/${roomId}/${machineId}`)
      .then(res => res.json())
      .then((data: ServerResponse<MachineStatusSpecific>) => {
        console.log(data)

        setCurrentMachine(data.data.machine)
      })
  }


  const eventRows = (currentMachine ? currentMachine.events : []).map((evt) => {
    return <Table.Tr key={evt.eventId} >
      <Table.Td>{evt.eventId}</Table.Td>
      <Table.Td>{statusCodeToEnum(evt.statusCode)}</Table.Td>
      <Table.Td>{formatDate(new Date(evt.timestamp), "dd/MM/yyyy hh:mm:ss a")}</Table.Td>

    </Table.Tr>
  })

  const update = () => {
    refetch()
    currentMachine && onTableRowClicked(currentMachine.machineId)
  }


  return <MantineProvider>
    <Container>
      <Stack>
        <Box>

          <h1>Hello RV!</h1>
          <p>There are currently {washerCount} washers and {dryerCount} dryers being checked.</p>
          <p><i>This is a work in progress! Don't expect accurate results or 100% uptime/coverage.</i></p>
          <Button onClick={update}> Refresh </Button>
        </Box>
        <Table highlightOnHover>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Status</Table.Th>
              <Table.Th>Room</Table.Th>
              <Table.Th>Machine</Table.Th>
              <Table.Th>Type</Table.Th>
              <Table.Th>Last updated</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>{rows}</Table.Tbody>
        </Table>
        <Divider />
        {currentMachine && <Box>
          <b>Events for machine {currentMachine?.name}</b>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>ID</Table.Th>
                <Table.Th>Status</Table.Th>
                <Table.Th>Time</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>{eventRows}</Table.Tbody>
          </Table>
        </Box>}

        <br />
        <Box>
          <i>

            Follow along on{" "}
            <Anchor href="https://github.com/HollaG/resiwash" target="_blank">
              Github
            </Anchor>
          </i>
        </Box>
      </Stack>

    </Container>

  </MantineProvider>;
}