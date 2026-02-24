import cron from "node-cron";
import { AppDataSource } from "../data-source";
import { Machine } from "../models/Machine";
import { Claim } from "../models/Claim";
import { MachineStatus } from "../core/types";
import {
  resetMachineStatusToAvailable,
  setMachineManualStatus,
  updateMachineStatusAfterTime,
} from "../services/machines.service";

/**
 * Scheduled job to check for "stuck" machines and clean up stale claims
 *
 * Runs every minute to:
 * 1. Find manual machines that are IN_USE or FINISHING with a cycle time
 * 2. If cycleTime - 5 <= activeTime < cycleTime, set machine to FINISHING status if not already
 * 3. Set status to AVAILABLE if activeTime >= cycleTime
 *
 * This serves as a safety net for crashed processes or missed status updates
 */
export const startMachineCycleEndChecker = () => {
  // Run every minute: '* * * * *'
  // Format: minute hour day month weekday
  const task = cron.schedule("* * * * *", async () => {
    try {
      console.log("[Job] Checking for stuck machines...");

      const machineRepository = AppDataSource.getRepository(Machine);

      // Query machines that could be stuck
      const potentiallyEndableMachines = await machineRepository
        .createQueryBuilder("machine")
        .leftJoinAndSelect("machine.room", "room")
        .leftJoinAndSelect("room.area", "area")
        .where("machine.currentStatus IN (:...statuses)", {
          statuses: [MachineStatus.IN_USE, MachineStatus.FINISHING],
        })
        .andWhere("machine.isManualEntry = :isManual", { isManual: true })
        .andWhere("machine.currentCycleTime IS NOT NULL")
        .andWhere("machine.lastAvailableTime IS NOT NULL")
        .getMany();

      console.log(
        `[Job] Found ${potentiallyEndableMachines.length} potentially endable machines`,
      );

      const now = new Date();
      let resetCount = 0;

      for (const machine of potentiallyEndableMachines) {
        // change back to available if it's been more than cycleTime + 30 seconds since last available time
        const elapsedMilliseconds =
          now.getTime() - machine.lastAvailableTime.getTime();
        const cycleTimeMilliseconds = machine.currentCycleTime! * 60 * 1000;
        const bufferMilliseconds = 30 * 1000; // 30 seconds buffer

        if (elapsedMilliseconds > cycleTimeMilliseconds + bufferMilliseconds) {
          console.log(
            `[Job] Resetting endable machine ${machine.machineId} (${machine.name}) - ` +
              `elapsed: ${Math.round(elapsedMilliseconds / 1000)}s, cycle time: ${machine.currentCycleTime}s`,
          );
          try {
            await updateMachineStatusAfterTime(
              MachineStatus.AVAILABLE,
              machine.machineId.toString(),
            );
            resetCount++;
          } catch (error) {
            console.error(
              `[Job] Failed to reset machine ${machine.machineId} to AVAILABLE:`,
              error,
            );
          }
        } else if (
          elapsedMilliseconds >= cycleTimeMilliseconds - 5 * 60 * 1000 &&
          machine.currentStatus !== MachineStatus.FINISHING
        ) {
          console.log(
            `[Job] Setting machine ${machine.machineId} (${machine.name}) to FINISHING - ` +
              `elapsed: ${Math.round(elapsedMilliseconds / 1000)}s, cycle time: ${machine.currentCycleTime}s`,
          );
          try {
            await updateMachineStatusAfterTime(
              MachineStatus.FINISHING,
              machine.machineId.toString(),
            );
            resetCount++;
          } catch (error) {
            console.error(
              `[Job] Failed to set machine ${machine.machineId} to FINISHING:`,
              error,
            );
          }
        }
      }

      if (resetCount > 0) {
        console.log(`[Job] Updated ${resetCount} machine(s)`);
      } else {
        console.log("[Job] No machines that need a state change found");
      }

      // Clean up old claims (4+ hours old)
      // console.log("[Job] Checking for stale claims...");
      // const claimRepository = AppDataSource.getRepository(Claim);

      // const fourHoursAgo = new Date(now.getTime() - 4 * 60 * 60 * 1000);

      // const staleClaims = await claimRepository
      //   .createQueryBuilder("claim")
      //   .where("claim.claimedAt < :fourHoursAgo", { fourHoursAgo })
      //   .getMany();

      // if (staleClaims.length > 0) {
      //   await claimRepository.remove(staleClaims);
      //   console.log(`[Job] Removed ${staleClaims.length} stale claim(s) (older than 4 hours)`);
      // } else {
      //   console.log("[Job] No stale claims found");
      // }
    } catch (error) {
      console.error("[Job] Error checking stuck machines:", error);
    }
  });

  console.log(
    "[Job] Stuck machines checker and claim cleanup started (runs every minute)",
  );

  return task;
};
