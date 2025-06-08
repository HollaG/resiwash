import { useState } from "react";
import { BASE_URL } from "../types/enums";
import { notifications } from "@mantine/notifications";

export function useCrud<T>(url: string) {
  const [data, setData] = useState<T>(null as unknown as T);
  const [loading, setLoading] = useState(false);

  const [error, setError] = useState<string | null>(null);

  const crudData = async ({
    body,
    method = "GET",
    append
  }: {
    body: any,
    method: string
    append?: string
  }) => {
    setLoading(true);
    try {
      const fullUrl = append ? `${BASE_URL}${url}/${append}` : `${BASE_URL}${url}`;
      const response = await fetch(fullUrl, {
        method: method,
        headers: {
          "Content-Type": "application/json",
        },
        body: method !== "GET" ? JSON.stringify(body) : null,
      });
      const data = await response.json();
      if (!response.ok) {
        // throw the data from the response
        throw new Error(data.error || "An error occurred while fetching data");
      }
      setData(data);
      setLoading(false);

      return { data, error: null };
    } catch (err: any) {
      setError(err.message);
      setLoading(false);

      notifications.show({
        title: 'Error',
        message: err.detail || err.message,
        color: 'red',
      })

      return { data: null, error: err.message };
    }
  }

  return {
    data,
    loading,
    error,
    crudData,
  };


}