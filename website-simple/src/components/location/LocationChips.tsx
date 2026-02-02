import { X, Plus } from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { cn } from '@/lib/utils';
import { Location } from '@/types/datatypes';

interface LocationChipsProps {
  savedLocations: { [areaId: number]: number[] };
  availableLocations: Location[] | undefined;
  onRemove: (areaId: number, roomId: number) => void;
  onAdd: (areaId: number, roomId: number) => void;
  className?: string;
}

/**
 * LocationChips component displays saved rooms as chips with a + button to add more
 * Layout:
 * ┌─────────────────────────────────────┐
 * │ YOUR ROOMS                          │
 * │ [Floor 3 ×] [Floor 5 ×] [+ Add]    │ ← Chips
 * └─────────────────────────────────────┘
 */
export function LocationChips({
  savedLocations,
  availableLocations,
  onRemove,
  onAdd,
  className,
}: LocationChipsProps) {
  const [isPickerOpen, setIsPickerOpen] = useState(false);

  // Get all saved room names
  const savedRoomChips = Object.entries(savedLocations).flatMap(([areaId, roomIds]) => {
    const area = availableLocations?.find((loc) => loc.areaId === Number(areaId));
    return roomIds.map((roomId) => {
      const room = area?.rooms.find((r) => r.roomId === roomId);
      return {
        areaId: Number(areaId),
        roomId,
        label: room?.name || 'Unknown Room',
      };
    });
  });

  const handleRemove = (areaId: number, roomId: number) => {
    onRemove(areaId, roomId);
  };

  return (
    <>
      <div className={cn('space-y-2', className)}>
        <h3 className="text-xs font-semibold uppercase tracking-wide text-dark-text-secondary dark:text-light-text-secondary">
          Your Rooms
        </h3>
        <div className="flex flex-wrap gap-2">
          <AnimatePresence initial={false}>
            {savedRoomChips.map((chip) => (
              <motion.button
                key={`${chip.areaId}-${chip.roomId}`}
                layout
                initial={{ opacity: 0, scale: 0.98, y: 6 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.98, y: 6 }}
                transition={{ duration: 0.16, ease: 'easeOut' }}
                className={cn(
                  'inline-flex items-center gap-2 rounded-full border-2 border-dark-border bg-dark-surface px-3 py-1.5',
                  'hover:border-accent-dark transition-colors',
                  'dark:border-light-border dark:bg-light-surface dark:hover:border-accent-light'
                )}
                onClick={() => handleRemove(chip.areaId, chip.roomId)}
              >
                <span className="text-sm font-medium text-dark-text-primary dark:text-light-text-primary">
                  {chip.label}
                </span>
                <X className="h-4 w-4 text-dark-text-secondary dark:text-light-text-secondary" />
              </motion.button>
            ))}
          </AnimatePresence>

          {/* Add button */}
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsPickerOpen(true)}
            className="rounded-full"
          >
            <Plus className="h-4 w-4 mr-1" />
            Add Room
          </Button>
        </div>

        {savedRoomChips.length === 0 && (
          <p className="text-sm text-dark-text-secondary dark:text-light-text-secondary">
            No rooms saved. Click "Add Room" to get started.
          </p>
        )}
      </div>

      {/* Room picker sheet */}
      <Sheet open={isPickerOpen} onOpenChange={setIsPickerOpen}>
        <SheetContent className="overflow-y-auto">
          <SheetHeader>
            <SheetTitle>Add a Room</SheetTitle>
          </SheetHeader>
          <div className="mt-6 space-y-6">
            {availableLocations?.map((location) => (
              <div key={location.areaId} className="space-y-3">
                <h4 className="font-semibold text-dark-text-primary dark:text-light-text-primary">
                  {location.name}
                </h4>
                <div className="grid gap-2">
                  {location.rooms.map((room) => {
                    const isSelected = savedLocations[location.areaId]?.includes(room.roomId);
                    return (
                      <button
                        key={room.roomId}
                        onClick={() => {
                          if (isSelected) {
                            onRemove(location.areaId, room.roomId);
                            return;
                          }

                          onAdd(location.areaId, room.roomId);
                          setIsPickerOpen(false);
                        }}
                        className={cn(
                          'flex items-center justify-between rounded-md border-2 p-3 text-left transition-all',
                          isSelected
                            ? 'border-accent-dark bg-accent-dark/10 dark:border-accent-light dark:bg-accent-light/10'
                            : 'border-dark-border hover:border-accent-dark dark:border-light-border dark:hover:border-accent-light'
                        )}
                      >
                        <div>
                          <div className="font-medium text-dark-text-primary dark:text-light-text-primary">
                            {room.name}
                          </div>
                          <div className="text-sm text-dark-text-secondary dark:text-light-text-secondary">
                            {room.machineCount} machines
                          </div>
                        </div>
                        {isSelected && (
                          <div className="h-5 w-5 rounded-full bg-accent-dark dark:bg-accent-light flex items-center justify-center">
                            <svg className="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                            </svg>
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
}
