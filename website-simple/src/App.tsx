// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { Anchor, Box, Button, Container, MantineProvider, Table } from '@mantine/core';
import { useEffect, useState } from 'react';
import { useFetch } from '@mantine/hooks';
import { statusCodeToEnum } from './types/enums';
import { MachineStatus } from './types/datatypes';
import { formatDistanceToNow } from 'date-fns';



export default function App() {
  const [washerCount, setWasherCount] = useState(0);
  const [dryerCount, setDryerCount] = useState(0);

  const [areaId] = useState(1);
  const [roomId] = useState(2);

  const [url] = useState("https://resiwash.marcussoh.com/api/v1")

  const { data, refetch } = useFetch<{
    status: number;
    data: MachineStatus[];
  }>(
    `${url}/areas/${areaId}/${roomId}`
  )

  useEffect(() => {
    if (data) {
      setWasherCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'washer').length);
      setDryerCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'dryer').length);
    }
  }, [data])

  const rows = ((data?.data) || []).map((machineStatus) => (
    <Table.Tr key={machineStatus.machine.machineId}>
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

  return <MantineProvider>
    <Container>
      <h1>Hello RV!</h1>
      <p>There are currently {washerCount} washers and {dryerCount} dryers being checked.</p>
      <p><i>This is a work in progress! Don't expect accurate results or 100% uptime/coverage.</i></p>
      <Button onClick={refetch}> Refresh </Button>
      <Table>
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

      <br />
      <Box>
        <i>

          Follow along on{" "}
          <Anchor href="https://github.com/HollaG/resiwash" target="_blank">
            Github
          </Anchor>
        </i>
      </Box>
    </Container>

  </MantineProvider>;
}