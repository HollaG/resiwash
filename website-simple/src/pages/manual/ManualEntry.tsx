import { useLocationMachines } from "@/hooks/query/useLocationMachines";
import { useMachineInfo } from "@/hooks/query/useMachineInfo";
import { useEffect, useState } from "react";
import * as Select from '@radix-ui/react-select';
import * as ToggleGroup from '@radix-ui/react-toggle-group';
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { BASE_URL } from "@/types/enums";
import { MachineStatus } from "@/types/datatypes";
import { MachineCell } from "@/components/room/MachineCell";
import { MachineDetailSheet } from "@/components/machine/MachineDetailSheet";
// URL: /manual?roomId=xxx&machineId=xxx&status=IN_USE
export const ManualEntry = () => {

  const queryParams = new URLSearchParams(window.location.search);
  const machineId = Number.isNaN(Number(queryParams.get('machineId'))) ? null : Number(queryParams.get('machineId'));
  const roomId = Number.isNaN(Number(queryParams.get('roomId'))) ? null : Number(queryParams.get('roomId'));
  const status = queryParams.get('status');


  const [isOpen, setIsOpen] = useState(false);
  const { data: locationMachines } = useLocationMachines({ roomId: roomId || 0, load: !!roomId });


  const [selectedMachineId, setSelectedValue] = useState<string | undefined>(machineId?.toString() || undefined);
  const [cycleTime, setCycleTime] = useState<string>("30");

  const { data: selectedMachineData } = useMachineInfo({
    machineId: Number(selectedMachineId) || 0,
    roomId: roomId || 0,
    load: !!machineId,
  });

  const [isLoading, setIsLoading] = useState(false);

  const onConfirm = () => {
    setIsLoading(true);
    fetch(`${BASE_URL}/machines/${selectedMachineId}/manual`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({

        status: MachineStatus.IN_USE, // hardcoded for now!
        cycleTime: Number(cycleTime),
      })
    }).then((response) => response.json()).then(res => {
      if (res.status === 'success') {
        // redirect user to home
        window.location.href = '/';
      }
    }).catch(console.error).finally(() => setIsLoading(false));
  }
  return <div className="min-h-screen bg-app">
    <div className="container mx-auto max-w-lg px-4 py-6 space-y-6">
      <h2 className="text-2xl font-bold text-center"> Use a machine</h2>
      <div className="flex gap-4">

        <Select.Root value={selectedMachineId} onValueChange={setSelectedValue}>
          <Select.Trigger className="w-full flex items-center justify-between px-4 py-3 bg-surface border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors" aria-label="Fruit">
            <Select.Value placeholder="Select a fruit..." />
            <Select.Icon className="ml-2">▽</Select.Icon>
          </Select.Trigger>
          <Select.Portal>
            <Select.Content className="bg-surface border border-app rounded-lg shadow-lg overflow-hidden z-50">
              <Select.Viewport className="p-1">
                {locationMachines?.map((machine) => (
                  <Select.Item key={machine.machineId} value={machine.machineId.toString()} className="px-4 py-2 text-primary font-mono cursor-pointer hover:bg-app rounded outline-none">
                    <Select.ItemText>{`${machine.name} (${machine.type}, ${machine.label})`}</Select.ItemText>
                  </Select.Item>
                ))}

              </Select.Viewport>
            </Select.Content>
          </Select.Portal>
        </Select.Root>
        <div className="shrink-0">

          {selectedMachineData && <MachineCell machine={{
            currentStatus: status as MachineStatus || MachineStatus.UNKNOWN,
            previousStatus: MachineStatus.UNKNOWN,
            ...selectedMachineData!
          }}
            onClick={() => setIsOpen(true)}
          />}
        </div>
      </div>

      <ToggleGroup.Root
        type="single"
        value={cycleTime}
        onValueChange={(value) => { value && setCycleTime(value) }}
        className="flex gap-2"
      >
        <ToggleGroup.Item
          value="30"
          className="flex-1 px-4 py-3 border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors data-[state=on]:bg-orange-200 data-[state=on]:text-app data-[state=on]:border-primary"
        >
          30 min
        </ToggleGroup.Item>
        <ToggleGroup.Item
          value="45"
          className="flex-1 px-4 py-3 border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors data-[state=on]:bg-orange-200 data-[state=on]:text-app data-[state=on]:border-primary"
        >
          45 min
        </ToggleGroup.Item>
        <ToggleGroup.Item
          value="60"
          className={"flex-1 px-4 py-3 border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors data-[state=on]:bg-orange-200 data-[state=on]:text-app data-[state=on]:border-primary"}
        >
          60 min
        </ToggleGroup.Item>
      </ToggleGroup.Root>

      <div className="w-full justify-center flex">

        <Button variant={'default'} onClick={onConfirm} disabled={!selectedMachineId || isLoading}>
          {isLoading ? 'Submitting...' : 'Confirm'}
        </Button>
      </div>
    </div>
    {selectedMachineData && <MachineDetailSheet machine={{
      currentStatus: selectedMachineData?.currentStatus || MachineStatus.UNKNOWN,
      previousStatus: selectedMachineData?.previousStatus || MachineStatus.UNKNOWN,
      ...selectedMachineData!
    }}
      isOpen={isOpen}
      onClose={() => setIsOpen(false)}

    />}
  </div>
}