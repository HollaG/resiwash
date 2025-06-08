// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { Anchor, Box, Button, Container, Divider, MantineProvider, Stack, Table } from '@mantine/core';
import { useEffect, useState } from 'react';
import { useFetch } from '@mantine/hooks';
import { Pages, statusCodeToEnum } from './types/enums';
import { MachineStatusOverview, MachineStatusSpecific, MachineWithEvents, ServerResponse } from './types/datatypes';
import { formatDate, formatDistanceToNow } from 'date-fns';
import { AdminPage } from './pages/admin/AdminPage';
import { HomePage } from './pages/home/HomePage';
import { QueryClientProvider } from '@tanstack/react-query';



export default function App() {
  const [page, setPage] = useState(Pages.HOME);


  if (page === Pages.ADMIN) {
    return <Stack>
      <Button onClick={() => setPage(Pages.HOME)}>Back to Home</Button>
      <AdminPage />
    </Stack>
  } else {
    return <Stack>
      <Button onClick={() => setPage(Pages.ADMIN)}>Back to Admin</Button>
      <HomePage />
    </Stack>
  }




}