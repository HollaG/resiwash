import cron from "node-cron";
import { AppDataSource } from "../data-source";
import { Machine } from "../models/Machine";
import { MachineStatus } from "../core/types";
import { resetMachineStatusToAvailable, setMachineManualStatus } from "../services/machines.service";

/**
 * Scheduled job to check for "stuck" machines that should have finished but haven't
 * 
 * Runs every minute to find manual machines that:
 * 1. Are currently IN_USE or FINISHING
 * 2. Have a currentCycleTime set
 * 3. Have exceeded their cycle time by more than 1 hour
 * 
 * This serves as a safety net for crashed processes or missed status updates
 */
export const startStuckMachinesChecker = () => {
  // Run every minute: '* * * * *'
  // Format: minute hour day month weekday
  const task = cron.schedule("* * * * *", async () => {
    try {
      console.log("[Job] Checking for stuck machines...");

      const machineRepository = AppDataSource.getRepository(Machine);

      // Query machines that could be stuck
      const potentiallyStuckMachines = await machineRepository
        .createQueryBuilder("machine")
        .where("machine.currentStatus IN (:...statuses)", {
          statuses: [MachineStatus.IN_USE, MachineStatus.FINISHING],
        })
        .andWhere("machine.isManualEntry = :isManual", { isManual: true })
        .andWhere("machine.currentCycleTime IS NOT NULL")
        .andWhere("machine.lastAvailableTime IS NOT NULL")
        .getMany();

      console.log(
        `[Job] Found ${potentiallyStuckMachines.length} potentially stuck machines`
      );

      const now = new Date();
      let resetCount = 0;

      for (const machine of potentiallyStuckMachines) {
        // Calculate elapsed time since the machine became unavailable
        const elapsedMinutes =
          (now.getTime() - machine.lastAvailableTime.getTime()) / 60000;

        // Threshold = cycle time + 1 hour buffer
        const thresholdMinutes = machine.currentCycleTime! + 60;

        if (elapsedMinutes > thresholdMinutes) {
          console.log(
            `[Job] Resetting stuck machine ${machine.machineId} (${machine.name}) - ` +
            `elapsed: ${Math.round(elapsedMinutes)}min, threshold: ${thresholdMinutes}min`
          );

          try {
            // Reset machine to available status
            await resetMachineStatusToAvailable(
              machine.machineId,
            );
            resetCount++;
          } catch (error) {
            console.error(
              `[Job] Failed to reset machine ${machine.machineId}:`,
              error
            );
          }
        }
      }

      if (resetCount > 0) {
        console.log(`[Job] Reset ${resetCount} stuck machine(s)`);
      } else {
        console.log("[Job] No stuck machines found");
      }
    } catch (error) {
      console.error("[Job] Error checking stuck machines:", error);
    }
  });

  console.log("[Job] Stuck machines checker started (runs every minute)");

  return task;
};
