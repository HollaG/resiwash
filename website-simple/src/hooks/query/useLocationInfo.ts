// get all location and rooms info

import { useQuery } from "@tanstack/react-query";
import { GET_LOCATION_INFO } from "./routes";
import { urlBuilder } from "../../utils/helpers";
import { Location, ServerResponse } from "../../types/datatypes";
import { STATUS_TYPES } from "../../types/rest";

// api:
export const useLocationInfo = () => {
  const { data, error, isLoading } = useQuery<Location[]>({
    queryKey: ["locationInfo"],
    queryFn: async () => {
      const response = await fetch(urlBuilder(GET_LOCATION_INFO));

      if (!response.ok) {
        throw new Error("Failed to fetch location info");
      }
      const data = (await response.json()) as ServerResponse<Location[]>;
      console.log("Location data fetched:", data);

      if (data.status === STATUS_TYPES.ERROR) {
        throw new Error(`Error fetching location info: ${data.status}`);
      }

      return data.data;
    },
    refetchOnWindowFocus: false,
  });

  return {
    data,
    error,
    isLoading,
  };
};
