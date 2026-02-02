import { useState } from 'react';
import { useSavedLocations } from '@/hooks/useSavedLocations';
import { useLocationInfo } from '@/hooks/query/useLocationInfo';
import { useLocationMachines } from '@/hooks/query/useLocationMachines';
import { LocationChips } from '@/components/location/LocationChips';
import { RoomCard } from '@/components/room/RoomCard';
import { MachineDetailSheet } from '@/components/machine/MachineDetailSheet';
import { StatusBadge } from '@/components/machine/StatusBadge';
import { MachineStatus, MachineStatusOverview } from '@/types/datatypes';
import { AnimatePresence, motion } from 'framer-motion';
import { fadeInUp } from '@/lib/animations';

/**
 * Redesigned Home page following the brutalist-utilitarian design from SPEC.md
 * 
 * Layout:
 * 1. Location chips (sticky below header)
 * 2. Primary/pinned room (always visible)
 * 3. Other saved rooms (scrollable)
 * 4. Empty state if no rooms saved
 */
export function HomeRedesign() {
  const { savedLocations, setSavedLocations } = useSavedLocations();
  const { data: availableLocations } = useLocationInfo();
  const [selectedMachine, setSelectedMachine] = useState<MachineStatusOverview | null>(null);

  // Flatten saved locations to get individual rooms
  const savedRooms = Object.entries(savedLocations).flatMap(([areaId, roomIds]) =>
    roomIds.map((roomId) => ({
      areaId: Number(areaId),
      roomId,
    }))
  );

  const handleAddRoom = (areaId: number, roomId: number) => {
    setSavedLocations((prev) => ({
      ...prev,
      [areaId]: [...(prev[areaId] || []), roomId],
    }));
  };

  const handleRemoveRoom = (areaId: number, roomId: number) => {
    setSavedLocations((prev) => {
      const rooms = prev[areaId]?.filter((id) => id !== roomId) || [];
      if (rooms.length === 0) {
        const newLocations = { ...prev };
        delete newLocations[areaId];
        return newLocations;
      }
      return {
        ...prev,
        [areaId]: rooms,
      };
    });
  };

  return (
    <div className="min-h-screen bg-app">
      <div className="container mx-auto max-w-6xl px-4 py-6 space-y-6">
        {/* Location selector - sticky */}
        <div className="sticky top-16 z-40 -mx-4 backdrop-blur px-4 py-4 border-b border-app"
          style={{ backgroundColor: 'rgba(var(--bg-rgb, 23, 23, 23), 0.95)' }}>
          <LocationChips
            savedLocations={savedLocations}
            availableLocations={availableLocations}
            onAdd={handleAddRoom}
            onRemove={handleRemoveRoom}
          />
        </div>

        {/* Status legend */}
        {savedRooms.length > 0 && (
          <div className="flex flex-wrap items-center gap-4 font-mono text-sm text-secondary">
            <div className="flex items-center gap-2">
              <StatusBadge status={MachineStatus.AVAILABLE} size="md" />
              <span>Available</span>
            </div>
            <div className="flex items-center gap-2">
              <StatusBadge status={MachineStatus.IN_USE} size="md" />
              <span>In Use</span>
            </div>
            <div className="flex items-center gap-2">
              <StatusBadge status={MachineStatus.FINISHING} size="md" />
              <span>Finishing</span>
            </div>
          </div>
        )}

        {/* Saved rooms */}
        {savedRooms.length > 0 ? (
          <motion.div
            className="space-y-6"
            initial="initial"
            animate="animate"
            variants={fadeInUp}
          >
            <AnimatePresence initial={false}>
              {savedRooms.map(({ areaId, roomId }, index) => (
                <motion.div
                  key={`${areaId}-${roomId}`}
                  layout
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 12 }}
                  transition={{ duration: 0.2, ease: 'easeOut' }}
                >
                  <RoomCardWrapper
                    areaId={areaId}
                    roomId={roomId}
                    isPinned={index === 0}
                    onMachineClick={(machineId, machines) => {
                      const machine = machines.find((m) => m.machineId === machineId);
                      if (machine) setSelectedMachine(machine);
                    }}
                  />
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        ) : (
          <motion.div
            className="flex flex-col items-center justify-center py-20 text-center"
            initial="initial"
            animate="animate"
            variants={fadeInUp}
          >
            <div className="space-y-4 max-w-md">
              <h2 className="text-3xl font-bold text-primary">
                No Rooms Saved
              </h2>
              <p className="text-lg text-secondary">
                Click "Add Room" above to start monitoring your laundry machines.
              </p>
            </div>
          </motion.div>
        )}
      </div>

      {/* Machine detail sheet */}
      <MachineDetailSheet
        machine={selectedMachine}
        isOpen={!!selectedMachine}
        onClose={() => setSelectedMachine(null)}
      />
    </div>
  );
}

/**
 * Wrapper component to fetch machine data for a room and render RoomCard
 */
function RoomCardWrapper({
  areaId,
  roomId,
  isPinned,
  onMachineClick,
}: {
  areaId: number;
  roomId: number;
  isPinned: boolean;
  onMachineClick: (machineId: number, machines: MachineStatusOverview[]) => void;
}) {
  const { data: machines, isLoading } = useLocationMachines({ roomId });
  const { data: locationData } = useLocationInfo();

  const area = locationData?.find((loc) => loc.areaId === areaId);
  const room = area?.rooms.find((r) => r.roomId === roomId);

  if (isLoading || !machines || !area || !room) {
    return (
      <div className="h-64 animate-pulse rounded-lg border bg-surface" 
        style={{ borderColor: 'var(--border-color)' }} />
    );
  }

  return (
    <RoomCard
      areaName={area.name}
      roomId={roomId}
      roomName={room.name}
      machines={machines}
      onMachineClick={(machineId) => onMachineClick(machineId, machines)}
      isPinned={isPinned}
    />
  );
}
