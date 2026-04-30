import { Alert, Anchor, Collapse, Stack, Title } from "@mantine/core";
import { useSavedLocations } from "../../hooks/useSavedLocations";
import { IconInfoCircle } from '@tabler/icons-react';
import { LocationSelector } from "../../components/location-selector/LocationSelector";
import { SavedLocationsWrapper } from "../../components/saved-locations-wrapper/SavedLocationsWrapper";
import { StatusExplainer } from "../../components/status-explainer/StatusExplainer";
export const Home = () => {
  const { hasNoSavedLocations } = useSavedLocations();

  // debug is if ?debug=true
  const queryString = window.location.search
  const params = new URLSearchParams(queryString)
  const debug = params.get("debug") === "true"


  return <Stack>
    <Alert variant="light" color="yellow" radius="xl" title="Development notice" icon={<IconInfoCircle />}>
      ResiWash is currently under development. Please report any issues <Anchor fz={"sm"} href="https://github.com/HollaG/resiwash/issues/new" target="_blank">on the GitHub Repo</Anchor>.
    </Alert>
    <Title order={1}>Welcome to ResiWash!</Title>

    {/* room selector */}
    <Collapse in={hasNoSavedLocations}>
      <Alert variant="light" color="violet" radius="xl" title="No saved locations found" icon={<IconInfoCircle />}>
        To see machine usage data, first select a few locations to subscribe to.
      </Alert>
    </Collapse>


    <LocationSelector />
    <StatusExplainer />
    {/* <LocationSelector2 /> */}
    <SavedLocationsWrapper debug={debug} />
  </Stack>
}

