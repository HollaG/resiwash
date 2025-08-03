import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { Button, Container, createTheme, MantineProvider } from '@mantine/core'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

import '@mantine/notifications/styles.css';
import { Notifications } from '@mantine/notifications'
import { AuthProvider } from './context/useAuth.tsx'


const queryClient = new QueryClient()

const theme = createTheme({
  primaryColor: 'violet',
  components: {
    Button: Button.extend({
      defaultProps: {
        variant: 'outline',
        radius: 'lg',
      },
    }),
  },
  fontFamily: 'Open Sans, sans-serif',
  headings: {
    fontFamily: 'Poppins, sans-serif',
  },
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>


      <QueryClientProvider client={queryClient}>

        <MantineProvider theme={theme}>
          <Notifications />
          <Container>
            <App />

          </Container>
        </MantineProvider>
      </QueryClientProvider>    </AuthProvider>
  </StrictMode>,
)
