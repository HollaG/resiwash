import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { Container, MantineProvider } from '@mantine/core'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

import '@mantine/notifications/styles.css';
import { Notifications } from '@mantine/notifications'


const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>

      <MantineProvider>
        <Notifications />
        <Container>
          <App />

        </Container>
      </MantineProvider>
    </QueryClientProvider>
  </StrictMode>,
)
