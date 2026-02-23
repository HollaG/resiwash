import { useLocationMachines } from "@/hooks/query/useLocationMachines";
import { useMachineInfo } from "@/hooks/query/useMachineInfo";
import { useState } from "react";
import * as Select from '@radix-ui/react-select';
import * as ToggleGroup from '@radix-ui/react-toggle-group';
import { Button } from "@/components/ui/button";
import { BASE_URL } from "@/types/enums";
import { MachineStatus, MachineType } from "@/types/datatypes";
import { MachineCell } from "@/components/room/MachineCell";
import { MachineDetailSheet } from "@/components/machine/MachineDetailSheet";
import { useRoomInfo } from "@/hooks/query/useRoomInfo";
// URL: /manual?roomId=xxx&machineId=xxx&status=IN_USE
export const ManualEntry = () => {

  const queryParams = new URLSearchParams(window.location.search);
  const machineId = Number.isNaN(Number(queryParams.get('machineId'))) ? null : Number(queryParams.get('machineId'));
  const status = queryParams.get('status');

  const [selectedMachineId, setSelectedValue] = useState<string | undefined>(machineId?.toString() || undefined);
  const { data: selectedMachineData } = useMachineInfo({
    machineId: Number(selectedMachineId) || 0,
    load: machineId !== null,

  });

  const [isOpen, setIsOpen] = useState(false);
  const { data: locationMachines } = useLocationMachines({ roomId: selectedMachineData?.roomId || 0, load: selectedMachineData?.roomId !== undefined });
  const { data: roomInfo } = useRoomInfo({ roomId: selectedMachineData?.roomId || 0, load: selectedMachineData?.roomId !== undefined, extra: true });

  const [cycleTime, setCycleTime] = useState<string>("30");

  // Determine machine type for cycle time options
  let cycleTimeOptions: { value: string; label: string }[] = [];
  if (selectedMachineData?.type === MachineType.WASHER) {
    cycleTimeOptions = [
      { value: '30', label: '30 min' },
      { value: '32', label: '32 min' },
      { value: '34', label: '34 min' },
    ];
  } else if (selectedMachineData?.type === MachineType.DRYER) {
    cycleTimeOptions = [
      { value: '30', label: '30 min' },
      { value: '45', label: '45 min' },
      { value: '60', label: '60 min' },
    ];
  } else {
    cycleTimeOptions = [
      { value: '30', label: '30 min' },
      { value: '45', label: '45 min' },
      { value: '60', label: '60 min' },
    ];
  }


  const [isLoading, setIsLoading] = useState(false);

  const onConfirm = () => {
    setIsLoading(true);
    // fetch(`${BASE_URL}/machines/${selectedMachineId}/manual`, {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: JSON.stringify({

    //     status: MachineStatus.IN_USE, // hardcoded for now!
    //     cycleTime: Number(cycleTime),
    //   })
    // }).then((response) => response.json()).then(res => {
    //   if (res.status === 'success') {
    //     // redirect user to home
    //     window.location.href = '/';
    //   }
    // }).catch(console.error).finally(() => setIsLoading(false));

    fetch(`${BASE_URL}/machines/${selectedMachineId}/claim`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({

        cycleTime: Number(cycleTime),
        fcmToken: "web_" + crypto.randomUUID(), // generate random token for claiming machine, prefixed with "web_" to indicate it's from the web interface
      })
    }).then((response) => response.json()).then(res => {
      if (res.status === 'success') {
        // redirect user to home
        window.location.href = '/';
      } else {
        console.error('Failed to claim machine:', res.message);
        alert('Failed to claim machine: ' + res.message);
      }
    }).catch(console.error).finally(() => setIsLoading(false));
  }
  return <div className="min-h-screen bg-app">
    <div className="container mx-auto max-w-lg px-4 py-6 space-y-6">
      <h2 className="text-2xl font-bold text-center"> Use a machine from {roomInfo?.shortName ?? roomInfo?.name}</h2>
      <div className="flex gap-4">

        <Select.Root value={selectedMachineId} onValueChange={setSelectedValue}>
          <Select.Trigger className="w-full flex items-center justify-between px-4 py-3 bg-surface border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors" aria-label="Fruit">
            <Select.Value placeholder="Select a machine..." />
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
        onValueChange={(value) => { if (value) setCycleTime(value) }}
        className="flex gap-2"
      >
        {cycleTimeOptions.map(option => (
          <ToggleGroup.Item
            key={option.value}
            value={option.value}
            className="flex-1 px-4 py-3 border border-app rounded-lg text-primary font-mono hover:border-secondary transition-colors data-[state=on]:bg-orange-200 data-[state=on]:text-app data-[state=on]:border-primary"
          >
            {option.label}
          </ToggleGroup.Item>
        ))}
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