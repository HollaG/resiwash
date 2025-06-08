// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { Button, Stack } from '@mantine/core';
import { useState } from 'react';
import { Pages } from './types/enums';
import { AdminPage } from './pages/admin/AdminPage';
import { HomePage } from './pages/home/HomePage';



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