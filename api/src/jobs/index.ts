import { startMachineCycleEndChecker } from "./automaticallySetManualMachineStatus";
import { startBrokenSensorChecker } from "./checkForBrokenSensors";

/**
 * Initialize all scheduled jobs
 * Call this function after the database connection is established
 */
export const initializeJobs = () => {
  console.log("[Jobs] Initializing scheduled jobs...");

  // Start the stuck machines checker (runs every minute)
  startMachineCycleEndChecker();

  startBrokenSensorChecker();

  // Add more jobs here as needed
  // Example: startOtherJob();

  console.log("[Jobs] All jobs initialized");
};
