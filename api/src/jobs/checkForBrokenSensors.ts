import cron from "node-cron";
import { AppDataSource } from "../data-source";
import { Machine } from "../models/Machine";
import { UpdateEvent } from "../models/UpdateEvent";
import { MachineStatus } from "../core/types";

/**
 * Logs machines whose sensors appear stale.
 * Runs every 10 minutes and checks only non-manual machines.
 */
const runBrokenSensorCheck = async () => {
  try {
    const machineRepo = AppDataSource.getRepository(Machine);

    // Pull all machines where data should come from sensors.
    const machines = await machineRepo.find({
      where: { isManualEntry: false },
    });

    const now = new Date();

    for (const machine of machines) {
      if (!machine.lastUpdated) {
        continue;
      }

      const diffMinutes =
        (now.getTime() - machine.lastUpdated.getTime()) / (1000 * 60);

      if (diffMinutes > 15) {
        // TODO: Handle broken sensor (e.g., notify, persist warning, etc.)
        console.log(
          `[Job] Machine ${machine.machineId} may have a broken sensor. Last update was ${diffMinutes.toFixed(1)} minutes ago.`,
        );

        // create fake actual event
        const brokenEvent = new UpdateEvent();
        brokenEvent.machine = machine;
        brokenEvent.status = MachineStatus.UNKNOWN;
        brokenEvent.cycleTime = null;
        brokenEvent.readings = null;
        await AppDataSource.getRepository(UpdateEvent).save(brokenEvent);

        // update the machine
        machine.previousStatus = machine.currentStatus;
        machine.currentStatus = MachineStatus.UNKNOWN;

        await machineRepo.save(machine);
      }
    }
  } catch (error) {
    console.error("[Job] Failed while checking for broken sensors:", error);
  }
};

export const startBrokenSensorChecker = () => {
  // Run once immediately on startup.
  void runBrokenSensorCheck();

  const task = cron.schedule("*/10 * * * *", async () => {
    await runBrokenSensorCheck();
  });

  return task;
};
