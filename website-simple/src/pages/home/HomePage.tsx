import { Table, Stack, Button, Box, Divider, Anchor, Input, TextInput } from "@mantine/core";
import { useFetch } from "@mantine/hooks";
import { formatDistanceToNow, formatDate } from "date-fns";
import { useState, useEffect } from "react";
import { MachineWithEvents, ServerResponse, MachineStatusOverview, MachineStatusSpecific } from "../../types/datatypes";
import { statusCodeToEnum, Pages } from "../../types/enums";
import { useAuth } from "../../context/useAuth";

export const HomePage = () => {
  const [washerCount, setWasherCount] = useState(0);
  const [dryerCount, setDryerCount] = useState(0);

  const [areaId, setAreaId] = useState(2);
  const [roomId, setRoomId] = useState(1);

  // const [url] = useState("http://localhost:3000/api/v1")
  const [url] = useState("https://resiwash.marcussoh.com/api/v1")

  const [currentMachine, setCurrentMachine] = useState<MachineWithEvents | null>(null)

  const { data, refetch } = useFetch<ServerResponse<MachineStatusOverview[]>>(
    `${url}/areas/${areaId}/${roomId}`
  )

  console.log("data", data?.data)

  useEffect(() => {
    if (data && data.data) {
      setWasherCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'washer').length);
      setDryerCount(data.data.filter((machineStatus) => machineStatus.machine.type === 'dryer').length);
    }
  }, [data])

  const rows = ((data?.data) || []).map((machineStatus) => (
    <Table.Tr key={machineStatus.machine.machineId} onClick={() => onTableRowClicked(machineStatus.machine.machineId)} style={{ cursor: "pointer" }}>
      <Table.Td>{statusCodeToEnum(machineStatus.status)}</Table.Td>
      <Table.Td>{machineStatus.machine?.room?.name}</Table.Td>
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
  const { currentUser, register, login: loginUser, logout  } = useAuth();
  const login = () => {
    const email = window.prompt("Enter email:");
    if (!email) return;
    const password = window.prompt("Enter password:");
    if (!password) return;

    // You can now use username and password, e.g., send to your API
    console.log("Username:", email, "Password:", password);

    loginUser(email, password)
      .then(() => {
        console.log("User logged in successfully");
      })
      .catch((error: any) => {
        console.error("Error logging user:", error);
      });
  };


  return <Stack>
    {!currentUser && <Button onClick={login}> Login </Button>}
    {currentUser && <Box>
      <b>Logged in as {currentUser.email}</b>
      <Button onClick={() => {
        logout();
      }}>Logout</Button>
      </Box>}

    <Box>

      <h1>Hello RV!</h1>
      <p>There are currently {washerCount} washers and {dryerCount} dryers being checked.</p>
      <p><i>This is a work in progress! Don't expect accurate results or 100% uptime/coverage.</i></p>
      <Button onClick={update}> Refresh </Button>
    </Box>

    <Box style={{display: "flex", gap: "10px"}}>
      <TextInput value={areaId} label="Area ID" onChange={e => setAreaId(parseInt(e.currentTarget.value))} type="number" />
      <TextInput value={roomId} label="Room ID" onChange={(e) => setRoomId(parseInt(e.currentTarget.value))} type="number" />
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
}