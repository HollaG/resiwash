// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { Stack } from '@mantine/core';

import { AdminPage } from './pages/admin/AdminPage';
import { Home } from './pages/home/Home';



export default function App() {

  // if url contains /admin, show admin page
  if (window.location.pathname.includes('/admin')) {
    return <Stack py="xl"><AdminPage /></Stack>
  } else {
    // setPage(Pages.HOME);
    return <Stack py="xl"><Home /> </Stack>
  }



}