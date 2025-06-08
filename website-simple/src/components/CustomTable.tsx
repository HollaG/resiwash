import { Button, Input, Table } from "@mantine/core";
import { useFetchData } from "../hooks/useFetchData";
import React from "react";

interface CustomTableProps<T> {
  headerKeys: { value: string, label: string, required?: boolean }[]
  url: string;
  // data: T[];
  onRowClick?: (item: T) => void;
  onDelete?: (item: T) => Promise<any>;
  onAdd?: (item: T) => Promise<any>;
  renderRow?: (item: T) => React.ReactNode;
  children?: React.ReactNode;
}

export const CustomTable = <T extends Object,>({
  headerKeys,
  url,
  // data,
  onRowClick,

  onDelete,
  onAdd }: CustomTableProps<T>) => {

  const { data, refetch } = useFetchData<T[]>(url);


  const rows = data?.map((item, index) => {
    return (
      <Table.Tr key={index} onClick={() => onRowClick?.(item)} style={{ cursor: "pointer" }}>
        {headerKeys.map((key) => {
          const keys = key.value.toString().split(".");

          console.log('keys', keys, item);

          const value = keys.reduce((acc, k) => acc && (acc as Record<string, any>)[k], item);

          console.log('value', value, item);
          return (
            // @ts-ignore
            <Table.Td key={key.value.toString()}>{value}</Table.Td>
          )
        })}

        {onDelete && <Table.Td><Button type="button" variant="outline" color="red" onClick={() => onDelete(item).then(() => { console.log("Item deleted. Refetching..."); refetch() })}>Delete</Button></Table.Td>}
      </Table.Tr>
    );
  })

  const onSubmit = (e: React.FormEvent) => {

    e.preventDefault();

    const formData = new FormData(e.currentTarget as HTMLFormElement);
    const newItem: any = {};
    headerKeys.forEach((key) => {
      newItem[onlyReturnPropertyAfterLastDot(key.value)] = formData.get(onlyReturnPropertyAfterLastDot(key.value.toString()));

    })

    onAdd?.(newItem).then(() => refetch());
  }

  const onlyReturnPropertyAfterLastDot = (value: string) => {
    const parts = value.split(".");
    if (parts.length === 1) return value; // No dot found, return the original value
    return parts[parts.length - 1];
  }


  return <form onSubmit={onSubmit}>
    <Table>
      <Table.Thead>
        <Table.Tr>
          {headerKeys && (headerKeys).map((key) => (
            <Table.Th key={key.value.toString()}>{key.label}</Table.Th>
          ))}
          {onDelete && <Table.Th>Actions</Table.Th>}
        </Table.Tr>
      </Table.Thead>
      <Table.Tbody>
        {rows}
        {onAdd && <Table.Tr>
          {(headerKeys).map((key) => (
            <Table.Td key={key.value.toString()}><Input required={key.required} name={onlyReturnPropertyAfterLastDot(key.value.toString())} /></Table.Td>
          ))}
          <Table.Td colSpan={Object.keys(headerKeys || {}).length + 1}>
            <Button type="submit">Add New</Button>
          </Table.Td>
        </Table.Tr>}
      </Table.Tbody>
    </Table>
  </form>
}