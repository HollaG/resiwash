import { useQuery } from "@tanstack/react-query";
import { urlBuilder } from "../../utils/helpers";
import { MachineWithRoomAndEvents } from "../../types/datatypes";

/**
 * Get detailed information about a specific machine in a room and area.
 * @param param0
 */
export const useMachineInfo = ({
  machineId,
  load = false,
}: {
  roomId: number;
  machineId: number;
  load?: boolean;
}) => {
  const { data, isLoading, error } = useQuery<MachineWithRoomAndEvents>({
    queryKey: ["machineInfo", machineId],
    queryFn: async ({ queryKey }) => {
      const [_, machineId] = queryKey;
      const response = await fetch(urlBuilder(`machines/${machineId}`));
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      if (data.status === "error") {
        throw new Error(`Error fetching machine info: ${data.message}`);
      }
      return data.data; // Assuming data.data contains the machine information
    },

    enabled: load, // Only run this query if load is true
  });
  return { data, isLoading, error };
};
