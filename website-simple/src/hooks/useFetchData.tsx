import { useQuery } from "@tanstack/react-query";
import { ServerResponse } from "../types/datatypes";
import { BASE_URL } from "../types/enums";

// const BASE_URL = "https://resiwash.marcussoh.com/api/v1";
 // Change to your local API URL

export const useFetchData = <T,>(url: string) => {
  const { data, error, isLoading, refetch } = useQuery<ServerResponse<T>>({
    queryKey: [url],
    queryFn: async () => {
      const response = await fetch(`${BASE_URL}${url}`);
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      return response.json();
    },
    refetchOnWindowFocus: false, // Optional: prevents refetching on window focus
  })

  return {
    data: data?.data,
    error,
    isLoading,
    refetch,
  };
}