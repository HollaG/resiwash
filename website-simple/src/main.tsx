import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import '@mantine/core/styles.css';
import App from './App.tsx'
import { MantineProvider, createTheme } from '@mantine/core';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from './context/useAuth.tsx'
import { useTheme } from './hooks/useTheme';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchInterval: 5000, // Auto-refresh every 5 seconds
      refetchOnWindowFocus: true,
    },
  },
})

const mantineTheme = createTheme({
  primaryColor: 'orange',
});

function Root() {
  const { theme } = useTheme();

  return (
    <MantineProvider
      theme={mantineTheme}
      defaultColorScheme="dark"
      forceColorScheme={theme}
    >
      <App />
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3000,
          style: {
            background: '#1a1a1a',
            color: '#ffffff',
            border: '1px solid var(--border-color)',
          },
        }}
      />
    </MantineProvider>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <QueryClientProvider client={queryClient}>
        <Root />
      </QueryClientProvider>
    </AuthProvider>
  </StrictMode>,
)
