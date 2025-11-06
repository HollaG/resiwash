import { getReadableMachineStatus, MachineStatus } from "../core/types";
import { getMessaging } from 'firebase-admin/messaging';
import { Machine } from "../models/Machine";

const getTopicNameForMachine = (machine: Machine): string => {
  return `machine_${machine.machineId}`
}

/**
 * 
 * @param machine Machine object with `room` and `area` joined !!important
 */
export const sendMachineStatusChangedNotification = async ({
  machine, oldStatus, newStatus,
}: {
  machine: Machine, oldStatus: MachineStatus, newStatus: MachineStatus
}) => {

  const message = {

    topic: getTopicNameForMachine(machine),
    notification: {
      title: `${machine.name} now ${getReadableMachineStatus(machine.currentStatus)}`,
      body: `${machine.room.name} @ ${machine.room.area.shortName}`,
    },
    data: {
      machineId: machine.machineId.toString(),

      // metadata for interaction

    }
  }


  console.log("[🔥🏠] Sending message to topic:", message.topic);
  try {
    const response = await getMessaging().send(message);
    console.log('[🔥🏠] Successfully sent message:', response);

    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending message:", e);
    throw e;
  }


}

export const sendPokeNotification = async (machine: Machine, fcmToken: string) => {
  const message = {
    token: fcmToken,
    notification: {
      title: `Poke: ${machine.name}`,
      body: `You have been poked in ${machine.room.name} @ ${machine.room.area.shortName}`,
    },
    data: {
      machineId: machine.machineId.toString(),
    }
  }
  console.log("[🔥🏠] Sending Poke message to token:", fcmToken);

  try {
    const response = await getMessaging().send(message);
    console.log('[🔥🏠] Successfully sent Poke message:', response);
    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending Poke message:", e);
    throw e;
  }
}