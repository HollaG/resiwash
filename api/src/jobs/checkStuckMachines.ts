import cron from "node-cron";
import { AppDataSource } from "../data-source";
import { Machine } from "../models/Machine";
import { Claim } from "../models/Claim";
import { MachineStatus } from "../core/types";
import { resetMachineStatusToAvailable, setMachineManualStatus } from "../services/machines.service";

/**
 * Scheduled job to check for "stuck" machines and clean up stale claims
 * 
 * Runs every minute to:
 * 1. Find manual machines that are IN_USE or FINISHING with a cycle time
 * 2. Reset machines that have exceeded their cycle time by more than 1 hour
 * 3. Remove claims that are older than 4 hours
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
        const thresholdMinutes = machine.currentCycleTime! + 10;

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

      // Clean up old claims (4+ hours old)
      console.log("[Job] Checking for stale claims...");
      const claimRepository = AppDataSource.getRepository(Claim);

      const fourHoursAgo = new Date(now.getTime() - 4 * 60 * 60 * 1000);

      const staleClaims = await claimRepository
        .createQueryBuilder("claim")
        .where("claim.claimedAt < :fourHoursAgo", { fourHoursAgo })
        .getMany();

      if (staleClaims.length > 0) {
        await claimRepository.remove(staleClaims);
        console.log(`[Job] Removed ${staleClaims.length} stale claim(s) (older than 4 hours)`);
      } else {
        console.log("[Job] No stale claims found");
      }
    } catch (error) {
      console.error("[Job] Error checking stuck machines:", error);
    }
  });

  console.log("[Job] Stuck machines checker and claim cleanup started (runs every minute)");

  return task;
};
