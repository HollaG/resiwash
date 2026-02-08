import { AppDataSource } from "../data-source";
import { Machine } from "../models/Machine";
import { UpdateEvent } from "../models/UpdateEvent";
import { MachineStatus } from "../core/types";
import { sendMachineStatusChangedNotification } from "../utils/firebase-messaging";
import { sendNotificationToClaimants } from "../utils/notifications";

const TIMEOUT_TRACKER = {} as { [machineId: number]: NodeJS.Timeout };

interface SetManualStatusParams {
  machineId: number;
  status: MachineStatus;
  cycleTime?: number;
}

/**
 * Trigger an initial "IN_USE" status update for a manual entry machine.
 * @param params
 */
export async function setMachineManualStatus(
  params: SetManualStatusParams,
): Promise<void> {
  const { machineId, status, cycleTime } = params;

  const machineRepository = AppDataSource.getRepository(Machine);
  const machine = await machineRepository.findOneBy({ machineId });

  if (!machine) {
    throw new Error("Machine not found");
  }

  if (!machine.isManualEntry) {
    throw new Error("Manual status update not allowed for this machine");
  }

  if (cycleTime && (typeof cycleTime !== "number" || cycleTime < 0)) {
    throw new Error("Cycle time must be a positive number");
  }

  console.log(
    "manual set status",
    { status, cycleTime },
    " for machine ",
    machine.machineId,
  );

  // create new UpdateEvent without sensor data
  const updateEvent = new UpdateEvent();
  updateEvent.machine = machine;
  updateEvent.status = status;
  updateEvent.readings = []; // indicate manual update
  updateEvent.machine = machine;
  updateEvent.cycleTime = cycleTime || null;

  const updateEventRepository = AppDataSource.getRepository(UpdateEvent);
  await updateEventRepository.save(updateEvent);

  // if status is set to MachineStatus.IN_USE and cycleTime is provided, set lastAvailableTime
  if (status === MachineStatus.IN_USE && cycleTime && cycleTime > 5) {
    // similar logic as events.controller.ts:createMultipleEvents
    const now = new Date();
    machine.previousStatusActiveTime =
      machine.lastChangeTime && machine.lastUpdated
        ? Math.floor(
            (machine.lastChangeTime?.getTime() -
              machine.lastUpdated?.getTime()) /
              1000,
          )
        : 0; // calculate how long the machine was in the previous status in seconds
    machine.lastAvailableTime = now;
    machine.lastChangeTime = now;
    machine.currentStatus = status;
    machine.previousStatus = status;
    machine.lastUpdated = now;

    await machineRepository.save(machine);
    const timeout = setTimeout(
      () => {
        updateMachineStatusAfterTime(MachineStatus.FINISHING, machine);
      },
      cycleTime * 60 * 1000 - 5 * 60 * 1000,
      // 10000,
    ); // convert minutes to milliseconds
    if (TIMEOUT_TRACKER[machine.machineId]) {
      clearTimeout(TIMEOUT_TRACKER[machine.machineId]);
    }
    TIMEOUT_TRACKER[machine.machineId] = timeout;

    // asynchronously send notification
    // note: we do not care if it succeeds or fails
    sendMachineStatusChangedNotification({
      machine: machine,
      oldStatus: machine.previousStatus,
      newStatus: machine.currentStatus,
    });

    // send notification to claimant if applicable
    sendNotificationToClaimants(machine).catch((e) => {}); // do nothing
  } else if (status === MachineStatus.IN_USE) {
    // invalid cycleTime
    throw new Error("Cycle time must be provided and greater than 5");
  }
}

/**
 * Automatically triggered 5 minutes before expected cycle end time
 *
 * @param status
 * @param machine
 */
const updateMachineStatusAfterTime = async (
  status: MachineStatus,
  machine: Machine,
) => {
  const machineRepository = AppDataSource.getRepository(Machine);

  machine.previousStatusActiveTime = machine.lastChangeTime
    ? Math.floor(
        (machine.lastChangeTime.getTime() - machine.lastUpdated!.getTime()) /
          1000,
      )
    : 0; // calculate how long the machine was in the previous status in seconds
  machine.previousStatus = machine.currentStatus;
  machine.currentStatus = status;
  machine.lastChangeTime = new Date();
  machine.lastUpdated = new Date();
  if (status === MachineStatus.AVAILABLE) {
    machine.lastAvailableTime = new Date(); // if machine now available, update lastAvailableTime, if its finishing, keep it the same
  }

  const updateEvent = new UpdateEvent();
  updateEvent.machine = machine;
  updateEvent.status = status;
  updateEvent.readings = []; // indicate manual update
  const updateEventRepository = AppDataSource.getRepository(UpdateEvent);
  await updateEventRepository.save(updateEvent);

  await machineRepository.save(machine);

  console.log(
    `Machine ${machine.machineId} status updated to ${status} after manual cycle time`,
  );

  // asynchronously send notification
  // note: we do not care if it succeeds or fails
  sendMachineStatusChangedNotification({
    machine: machine,
    oldStatus: machine.previousStatus,
    newStatus: machine.currentStatus,
  });

  // send notification to claimant if applicable
  sendNotificationToClaimants(machine).catch((e) => {}); // do nothing

  if (status === MachineStatus.FINISHING) {
    const timeout = setTimeout(
      () => {
        updateMachineStatusAfterTime(MachineStatus.AVAILABLE, machine);
      },
      5 * 60 * 1000,
    );
    if (TIMEOUT_TRACKER[machine.machineId]) {
      clearTimeout(TIMEOUT_TRACKER[machine.machineId]);
    }
    TIMEOUT_TRACKER[machine.machineId] = timeout;
  } else {
    // clear timeout tracker
    if (TIMEOUT_TRACKER[machine.machineId]) {
      clearTimeout(TIMEOUT_TRACKER[machine.machineId]);
      delete TIMEOUT_TRACKER[machine.machineId];
    }
  }
};
