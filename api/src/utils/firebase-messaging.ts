import {
  getReadableMachineStatus,
  MachineStatus,
  MachineType,
} from "../core/types";
import {
  getMessaging,
  Message,
  MulticastMessage,
} from "firebase-admin/messaging";
import { Machine } from "../models/Machine";
import { AppDataSource } from "../data-source";

const getTopicNameForMachine = (machine: Machine): string => {
  return `machine_${machine.machineId}`;
};

const getTopicNameForBulkSubscription = (machine: Machine): string => {
  return `group_${machine.roomId}_${machine.type.toLowerCase()}`;
};

type CustomDataPayload = {
  [key: string]: string;
  channel: "claimed" | "subscribed" | "poke";
};

type CustomMessage = Message & { data: CustomDataPayload };
type CustomMulticastMessage = MulticastMessage & { data: CustomDataPayload };

/**
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
export const sendMachineStatusChangedNotification = async ({
  machine,
  oldStatus,
  newStatus,
}: {
  machine: Machine;
  oldStatus: MachineStatus;
  newStatus: MachineStatus;
}) => {
  const message: CustomMessage = {
    topic: getTopicNameForMachine(machine),
    notification: {
      title: `${machine.name} now ${getReadableMachineStatus(
        machine.currentStatus,
      )}`,
      body: `${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name}`,
    },
    android: {
      notification: {
        channelId: "claimed",
      },
    },
    data: {
      machineId: machine.machineId.toString(),
      channel: "subscribed",
      // metadata for interaction
    },
  };

  console.log("[🔥🏠] Sending message to topic:", message.topic);
  try {
    const response = await getMessaging().send(message);
    console.log("[🔥🏠] Successfully sent message:", response);

    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending message:", e);
    throw e;
  }
};

/**
 * Send a data-only notification to the device, prompting it to handle the status change on-device.
 * https://firebase.flutter.dev/docs/messaging/usage
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
export const sendClaimedMachineStatusChangedNotification = async ({
  machine,
  fcmToken,
}: {
  machine: Machine;
  oldStatus?: MachineStatus;
  newStatus?: MachineStatus;
  fcmToken: string;
}) => {
  let title = "";
  let body = "";
  let secondsTillCompletion = null;

  // state maps
  // IN_USE
  // FINISHING
  // AVAILABLE
  if (machine.currentStatus === MachineStatus.IN_USE) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} running...`;
    const expectedEndTime =
      machine.lastAvailableTime!.getTime() +
      (machine.currentCycleTime ? machine.currentCycleTime * 60000 : 0);
    body = `Expected to finish by [[ expectedEndTime ]].`;
    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);
  } else if (machine.currentStatus === MachineStatus.FINISHING) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} finishing in approx. 5 - 10 minutes...`;
    body = `Please be ready to collect your clothes soon!`;

    if (machine.type === MachineType.WASHER) {
      // search for nearby available dryers in the same room and add to notification body
      // this is to encourage users to switch to dryer right after washing cycle ends, reducing the chance of them forgetting about the machine
      const nearbyAvailableDryers = await AppDataSource.getRepository(
        Machine,
      ).find({
        where: {
          roomId: machine.roomId,
          type: MachineType.DRYER,
          currentStatus: MachineStatus.AVAILABLE || MachineStatus.FINISHING, // also include finishing dryers since they might be finishing before the washer and become available right after
        },
      });
      if (nearbyAvailableDryers.length > 0) {
        body += ` Dryers available / finishing: ${nearbyAvailableDryers.map((dryer) => dryer.name).join(", ")}.`;
      } else {
        body += ` Unfortunately, there is no available dryer at the moment.`;
      }
    }
  } else if (machine.currentStatus === MachineStatus.AVAILABLE) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} has finished!`;
    body = `Please collect your clothes as soon as possible.`;

    if (machine.type === MachineType.WASHER) {
      // search for nearby available dryers in the same room and add to notification body
      // this is to encourage users to switch to dryer right after washing cycle ends, reducing the chance of them forgetting about the machine
      const nearbyAvailableDryers = await AppDataSource.getRepository(
        Machine,
      ).find({
        where: {
          roomId: machine.roomId,
          type: MachineType.DRYER,
          currentStatus: MachineStatus.AVAILABLE || MachineStatus.FINISHING, // also include finishing dryers since they might be finishing before the washer and become available right after
        },
      });
      if (nearbyAvailableDryers.length > 0) {
        body += ` Dryers available / finishing: ${nearbyAvailableDryers.map((dryer) => dryer.name).join(", ")}.`;
      } else {
        body += ` Unfortunately, there is no available dryer at the moment.`;
      }
    }
  }

  const message: CustomMessage = {
    token: fcmToken,

    // notification: {
    //   title: `${machine.name} now ${getReadableMachineStatus(
    //     machine.currentStatus
    //   )}`,
    //   body: `${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name}`,
    // },
    // android: {
    //   notification: {
    //     channelId: "claimed",
    //   },
    // },
    android: {
      priority: "high",
    },
    // Add APNS (Apple) config
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
      headers: {
        "apns-push-type": "background",
        "apns-priority": "5", // Must be `5` when `contentAvailable` is set to true.
        "apns-topic": "io.flutter.plugins.firebase.messaging", // bundle identifier
      },
    },
    data: {
      machineId: machine.machineId.toString(),
      machineName: machine.name,
      machineRoomName: machine.room.name,
      machineAreaShortName:
        machine.room.area.shortName || machine.room.area.name,
      machineCurrentStatus: machine.currentStatus,
      machinePreviousStatus: machine.previousStatus,

      channel: "claimed",

      title,
      body,
      secondsTillCompletion: secondsTillCompletion
        ? secondsTillCompletion.toString()
        : "",
    },
  };

  console.log("[🔥🏠] Sending message to token:", fcmToken);
  try {
    const response = await getMessaging().send(message);
    console.log("[🔥🏠] Successfully sent message:", response);

    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending message:", e);
    throw e;
  }
};

/**
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
export const sendMachineGroupStatusChangedNotification = async ({
  machine,
}: {
  machine: Machine;
}) => {
  let cycleTimeInfo = "";
  if (machine.currentCycleTime) {
    cycleTimeInfo = ` Expected to finish by ${new Date(
      machine.lastAvailableTime!.getTime() + machine.currentCycleTime * 60000,
    ).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    })} (${machine.currentCycleTime}m cycle). `;
  }
  const message: CustomMessage = {
    topic: getTopicNameForBulkSubscription(machine),
    notification: {
      title: `${machine.name} now ${getReadableMachineStatus(
        machine.currentStatus,
      )}`,
      body:
        cycleTimeInfo +
        `${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name}`,
    },
    android: {
      notification: {
        channelId: "subscribed",
      },
    },
    data: {
      machineId: machine.machineId.toString(),
      channel: "subscribed",
      // metadata for interaction
    },
  };

  console.log("[🔥🏠] Sending message to topic:", message.topic);
  try {
    const response = await getMessaging().send(message);
    console.log("[🔥🏠] Successfully sent message:", response);

    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending message:", e);
    throw e;
  }
};

/**
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
// export const sendClaimedMachineStatusChangedNotifications = async ({
//   machine,
//   oldStatus,
//   newStatus,
//   fcmTokens,
// }: {
//   machine: Machine;
//   oldStatus: MachineStatus;
//   newStatus: MachineStatus;
//   fcmTokens: string[];
// }) => {
//   const message: CustomMulticastMessage = {
//     tokens: fcmTokens,

//     notification: {
//       title: `${machine.name} now ${getReadableMachineStatus(
//         machine.currentStatus
//       )}`,
//       body: `${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name}`,
//     },
//     android: {
//       notification: {
//         channelId: "claimed",
//       },
//     },
//     data: {
//       machineId: machine.machineId.toString(),
//       machineName: machine.name,
//       machineRoomName: machine.room.name,
//       machineAreaShortName: machine.room.area.shortName || machine.room.area.name,
//       machineCurrentStatus: machine.currentStatus,
//       machinePreviousStatus: machine.previousStatus,

//       channel: "claimed",
//     },
//   };

//   console.log("[🔥🏠] Sending message to tokens:", fcmTokens);
//   try {
//     const response = await getMessaging().sendEachForMulticast(message);
//     console.log("[🔥🏠] Successfully sent message:", response);

//     return response;
//   } catch (e) {
//     console.error("[🔥🏠] Error sending message:", e);
//     throw e;
//   }
// };

export const sendPokeNotification = async (
  machine: Machine,
  fcmToken: string,
) => {
  const message: CustomMessage = {
    token: fcmToken,
    // notification: {
    //   title: `Reminder: ${machine.name}`,
    //   body: `Please clear your clothes from ${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name}`,
    // },
    // android: {
    //   notification: {
    //     channelId: "poke",
    //     priority: "high",
    //   },
    // },

    apns: {
      headers: {
        "apns-priority": "5",
      },
    },
    data: {
      machineId: machine.machineId.toString(),
      channel: "poke",
      title: `Reminder: ${machine.name}`,
      body: `Please clear your clothes from ${machine.name} (${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name})`,
    },
  };
  console.log("[🔥🏠] Sending Poke message to token:", fcmToken);

  try {
    const response = await getMessaging().send(message);
    console.log("[🔥🏠] Successfully sent Poke message:", response);
    return response;
  } catch (e) {
    console.error("[🔥🏠] Error sending Poke message:", e);
    throw e;
  }
};
