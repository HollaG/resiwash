import { useQuery } from "@tanstack/react-query";
import { urlBuilder } from "../../utils/helpers";
import { AlignedData } from "uplot";

interface GetEventsFormattedResponse {
  points: AlignedData;
  series: string[];
}

/**
 * Get events for a specific machine.
 * @param param0
 */
export const useEventInfo = ({
  machineId,
  load = false,
  raw = false,
}: {
  machineId: number;
  load?: boolean;
  raw?: boolean;
}) => {
  const { data, isLoading, error } = useQuery<GetEventsFormattedResponse>({
    queryKey: ["machineInfo", machineId, raw],
    queryFn: async ({ queryKey }) => {
      const [_, machineId, raw] = queryKey;
      let resource = "events/formatted";
      const response = await fetch(
        urlBuilder(resource) +
          "?" +
          new URLSearchParams({
            "machineIds[]": (machineId as number).toString(),
            raw: (raw as boolean) ? "true" : "false",
          }).toString()
      );
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      if (data.status === "error") {
        throw new Error(`Error fetching event info: ${data.message}`);
      }
      return data.data; // Assuming data.data contains the machine information
    },

    enabled: load, // Only run this query if load is true
  });
  return { data, isLoading, error };
};
