import { Alert, Collapse, Stack, Title } from "@mantine/core";
import { useSavedLocations } from "../../hooks/useSavedLocations";
import { IconInfoCircle } from '@tabler/icons-react';
import { LocationSelector } from "../../components/location-selector/LocationSelector";
import { SavedLocationsWrapper } from "../../components/saved-locations-wrapper/SavedLocationsWrapper";
export const Home = () => {
  const { hasNoSavedLocations } = useSavedLocations();
  return <Stack>
    <Title order={1}>Welcome to Resiwash!</Title>

    {/* room selector */}
    <Collapse in={hasNoSavedLocations}>
      <Alert variant="light" color="violet" radius="xl" title="No saved locations found" icon={<IconInfoCircle />}>
        To see machine usage data, first select a few locations to subscribe to.
      </Alert>
    </Collapse>

    <LocationSelector />
    <SavedLocationsWrapper />
  </Stack>
}

