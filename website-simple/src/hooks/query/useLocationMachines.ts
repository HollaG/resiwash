import { useQuery } from "@tanstack/react-query";
import { urlBuilder } from "../../utils/helpers";
import { MachineStatusOverview } from "../../types/datatypes";

export const useLocationMachines = ({ roomId }: { roomId: number }) => {
  const { data, isLoading, error } = useQuery<MachineStatusOverview[]>({
    queryKey: ["machineInfo", roomId],
    queryFn: async ({ queryKey }) => {
      const [_, roomId] = queryKey;
      const response = await fetch(urlBuilder(`machines?roomIds[]=${roomId}`));
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      if (data.status === "error") {
        throw new Error(`Error fetching machine info: ${data.message}`);
      }
      return data.data as MachineStatusOverview[];
    },
  });

  return { data, isLoading, error };
};
