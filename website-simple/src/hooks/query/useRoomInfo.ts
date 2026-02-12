import { useQuery } from "@tanstack/react-query";
import { urlBuilder } from "../../utils/helpers";
import { Room } from "../../types/datatypes";

/**
 * Get detailed information about a specific room.
 * @param param0
 */
export const useRoomInfo = ({
  roomId,
  extra,
  depth,
  load = false,
}: {
  roomId: number;
  extra?: boolean;
  depth?: number;
  load?: boolean;
}) => {
  const { data, isLoading, error } = useQuery<Room>({
    queryKey: ["roomInfo", roomId, extra, depth],
    queryFn: async ({ queryKey }) => {
      const [_, roomId, extra, depth] = queryKey;

      const params = new URLSearchParams();
      if (extra !== undefined) params.append("extra", String(extra));
      if (depth !== undefined) params.append("depth", String(depth));

      const queryString = params.toString();
      const url = urlBuilder(
        `rooms/${roomId}${queryString ? `?${queryString}` : ""}`
      );

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      if (data.status === "error") {
        throw new Error(`Error fetching room info: ${data.message}`);
      }
      return data.data; // Assuming data.data contains the room information
    },

    enabled: load, // Only run this query if load is true
  });
  return { data, isLoading, error };
};
