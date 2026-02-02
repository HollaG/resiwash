import { useQuery } from "@tanstack/react-query";
import { ServerResponse } from "../types/datatypes";
import { BASE_URL } from "../types/enums";
import auth from "../core/firebase";

// const BASE_URL = "https://resiwash.marcussoh.com/api/v2";
// Change to your local API URL

export const useFetchData = <T,>(url: string) => {
  const user = auth.currentUser;
  const { data, error, isLoading, refetch } = useQuery<ServerResponse<T>>({
    queryKey: [url, auth.currentUser?.uid],
    queryFn: async () => {
      const token = user && (await user.getIdToken());
      const response = await fetch(`${BASE_URL}${url}`, {
        method: 'GET',
        headers: {
          "Authorization": token ? `Bearer ${token}` : "",
          "Content-Type": "application/json",
        }
      });
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