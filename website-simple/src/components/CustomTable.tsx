import { Button, Input, Table } from "@mantine/core";
import { useFetchData } from "../hooks/useFetchData";
import React, { useRef } from "react";

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
  onAdd,
  renderRow,
  children
}: CustomTableProps<T>) => {

  const { data, refetch } = useFetchData<T[]>(url);

  const inputRefs = useRef<Record<string, HTMLInputElement | null>>({});

  const rows = data?.map((item, index) => {
    return (
      <Table.Tr key={index} onClick={() => onRowClick?.(item)} style={{ cursor: "pointer" }}>
        {headerKeys.map((key) => {
          const keys = key.value.toString().split(".");

          console.log('keys', keys, item);

          const value = keys.reduce((acc, k) => acc && (acc as Record<string, any>)[k], item);

          console.log('value', value, item);
          return (
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
      newItem[key.value] = formData.get(key.value.toString());

    })

    onAdd?.(newItem).then(() => refetch());
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
            <Table.Td key={key.value.toString()}><Input required={key.required} name={key.value.toString()} /></Table.Td>
          ))}
          <Table.Td colSpan={Object.keys(headerKeys || {}).length + 1}>
            <Button type="submit">Add New</Button>
          </Table.Td>
        </Table.Tr>}
      </Table.Tbody>
    </Table>
  </form>
}