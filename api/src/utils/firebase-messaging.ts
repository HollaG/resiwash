import {
  getReadableMachineStatus,
  isAvailableLike,
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
import { In } from "typeorm";

const getTopicNameForMachine = (machine: Machine): string => {
  return `machine_${machine.machineId}`;
};

const getTopicNameForBulkSubscription = (machine: Machine): string => {
  return `group_${machine.roomId}_${machine.type.toLowerCase()}`;
};

const IOS_APP_BUNDLE_ID = "com.resiwash.app";

type CustomDataPayload = {
  [key: string]: string;
  channel: "claimed" | "subscribed" | "poke";
};

type CustomMessage = Message & { data: CustomDataPayload };
type CustomMulticastMessage = MulticastMessage & { data: CustomDataPayload };

export type DataMessageForDeviceTimers = {
  title: string;
  body: string;
  secondsTillCompletion: number; // send as string to avoid firebase data message parsing issues
  machineId: number;
  machineName: string;
  machineRoomName: string;
  machineType: string;
};

/**
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
// export const sendMachineStatusChangedNotification = async ({
//   machine,
// }: {
//   machine: Machine;
// }) => {
//   const message: CustomMessage = {
//     topic: getTopicNameForMachine(machine),
//     notification: {
//       title: `${machine.name} now ${getReadableMachineStatus(
//         machine.currentStatus,
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
//       channel: "subscribed",
//       // metadata for interaction
//     },
//   };

//   console.log("[🔥🏠] Sending message to topic:", message.topic);
//   try {
//     const response = await getMessaging().send(message);
//     console.log("[🔥🏠] Successfully sent message:", response);

//     return response;
//   } catch (e) {
//     console.error("[🔥🏠] Error sending message:", e);
//     throw e;
//   }
// };

/**
 * Send a data-only notification to the device, prompting it to handle the status change on-device.
 * https://firebase.flutter.dev/docs/messaging/usage
 *
 * @param machine Machine object with `room` and `area` and `claim` joined !!important
 */
export const sendClaimedMachineStatusChangedNotification = async ({
  machineId,
  fcmToken,
}: {
  machineId: number;
  fcmToken: string;
}) => {
  if (fcmToken.startsWith("web_")) {
    // just return as we use web_ prefix to indicate web clients, which don't need this notification
    return;
  }

  const machine = await AppDataSource.getRepository(Machine)
    .createQueryBuilder("machine")
    .leftJoinAndSelect("machine.room", "room")
    .leftJoinAndSelect("room.area", "area")
    .leftJoinAndSelect("machine.claim", "claim") // join with Claim to get cycle time for notification
    .where("machine.machineId = :id", { id: machineId })
    .getOne();

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
      (machine.claim.cycleTime ? machine.claim.cycleTime * 60000 : 0);
    body = `Expected to finish by [[ expectedEndTime ]].`;
    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);
  } else if (machine.currentStatus === MachineStatus.FINISHING) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} finishing in approx. 5 - 10 minutes...`;
    body = `Please be ready to collect your clothes soon!`;
    const expectedEndTime =
      machine.lastAvailableTime!.getTime() +
      (machine.claim.cycleTime ? machine.claim.cycleTime * 60000 : 0);
    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);

    if (machine.type === MachineType.WASHER) {
      // search for nearby available dryers in the same room and add to notification body
      // this is to encourage users to switch to dryer right after washing cycle ends, reducing the chance of them forgetting about the machine
      const nearbyAvailableDryers = await AppDataSource.getRepository(
        Machine,
      ).find({
        where: {
          roomId: machine.roomId,
          type: MachineType.DRYER,
          currentStatus: In([
            MachineStatus.AVAILABLE,
            MachineStatus.FINISHED,
            MachineStatus.FINISHING,
          ]), // special case: available-like and finishing
        },
      });
      if (nearbyAvailableDryers.length > 0) {
        body += ` Dryers available / finishing: ${nearbyAvailableDryers.map((dryer) => dryer.name).join(", ")}.`;
      } else {
        body += ` Unfortunately, there is no available dryer at the moment.`;
      }
    }
  } else if (machine.currentStatus === MachineStatus.FINISHED) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room?.name} has finished!`;
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
          currentStatus: In([
            MachineStatus.AVAILABLE,
            MachineStatus.FINISHED,
            MachineStatus.FINISHING,
          ]), // special case: available-like and finishing
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
        "apns-topic": IOS_APP_BUNDLE_ID,
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

      machineType: machine.type.toString().toLowerCase(),

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
  } catch (e: any) {
    console.error("[🔥🏠] Error sending message:", e);

    // Check if the error is due to an invalid/unregistered token
    if (e.code === "messaging/registration-token-not-registered") {
      console.log(
        "[🔥🏠] Token no longer registered, will be cleaned up:",
        fcmToken,
      );
      // Return the error info so the caller can handle cleanup
      return { error: "token-not-registered", fcmToken };
    }

    throw e;
  }
};

/**
 * Send a claim notification and also tell the device to start the timer*
 *
 *
 */
export const sendNewlyClaimedMachineNotification = async ({
  machineId,
  fcmToken,
}) => {
  if (fcmToken.startsWith("web_")) {
    // just return as we use web_ prefix to indicate web clients, which don't need this notification
    return;
  }

  const machine = await AppDataSource.getRepository(Machine)
    .createQueryBuilder("machine")
    .leftJoinAndSelect("machine.room", "room")
    .leftJoinAndSelect("room.area", "area")
    .leftJoinAndSelect("machine.claim", "claim") // join with Claim to get cycle time for notification
    .where("machine.machineId = :id", { id: machineId })
    .getOne();

  let title = "";
  let body = "";
  let secondsTillCompletion = null;

  if (
    isAvailableLike(machine.currentStatus) ||
    machine.currentStatus === MachineStatus.UNKNOWN
  ) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room?.name} claimed.`;

    const expectedEndTime =
      Date.now() +
      (machine.claim.cycleTime ? machine.claim.cycleTime * 60000 : 0);
    body = `Expected to finish by [[ expectedEndTime ]].`;
    body = `Remember to start your machine! Expected to finish around [[ expectedEndTime ]].`;

    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);
  } else if (machine.currentStatus === MachineStatus.IN_USE) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} running...`;
    const expectedEndTime =
      machine.lastAvailableTime!.getTime() +
      (machine.claim.cycleTime ? machine.claim.cycleTime * 60000 : 0);
    body = `Expected to finish by [[ expectedEndTime ]].`;
    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);
  } else if (machine.currentStatus === MachineStatus.FINISHING) {
    title = `${machine.name} @ ${machine.room?.shortName || machine.room.name} finishing in approx. 5 - 10 minutes...`;
    body = `Please be ready to collect your clothes soon!`;
    const expectedEndTime =
      machine.lastAvailableTime!.getTime() +
      (machine.claim.cycleTime ? machine.claim.cycleTime * 60000 : 0);
    secondsTillCompletion = Math.floor((expectedEndTime - Date.now()) / 1000);

    if (machine.type === MachineType.WASHER) {
      // search for nearby available dryers in the same room and add to notification body
      // this is to encourage users to switch to dryer right after washing cycle ends, reducing the chance of them forgetting about the machine
      const nearbyAvailableDryers = await AppDataSource.getRepository(
        Machine,
      ).find({
        where: {
          roomId: machine.roomId,
          type: MachineType.DRYER,
          currentStatus: In([
            MachineStatus.AVAILABLE,
            MachineStatus.FINISHED,
            MachineStatus.FINISHING,
          ]), // special case: available-like and finishing
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
        "apns-topic": IOS_APP_BUNDLE_ID,
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

      machineType: machine.type.toString().toLowerCase(),

      channel: "claimed",
      forceShowTimer: "true",

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

    return message.data;
  } catch (e: any) {
    console.error("[🔥🏠] Error sending message:", e);

    // Check if the error is due to an invalid/unregistered token
    if (e.code === "messaging/registration-token-not-registered") {
      console.log(
        "[🔥🏠] Token no longer registered, will be cleaned up:",
        fcmToken,
      );
      // Return the error info so the caller can handle cleanup
      return { error: "token-not-registered", fcmToken };
    }

    throw e;
  }
};

/**
 *
 * @param machine Machine object with `room` and `area` joined !!important
 */
export const sendMachineGroupStatusChangedNotification = async ({
  machineId,
  machine: _machine,
}: {
  machineId: number;
  machine?: Machine; // Must have room, area, and claim joined.
}) => {
  const machine =
    _machine ||
    (await AppDataSource.getRepository(Machine)
      .createQueryBuilder("machine")
      .leftJoinAndSelect("machine.room", "room")
      .leftJoinAndSelect("room.area", "area")
      .leftJoinAndSelect("machine.claim", "claim") // join with Claim to get cycle time for notification. Don't need FCM token
      .where("machine.machineId = :id", { id: machineId })
      .getOne());
  let cycleTimeInfo = "";
  if (
    machine.claim &&
    machine.claim.cycleTime &&
    (machine.currentStatus === MachineStatus.FINISHING ||
      machine.currentStatus === MachineStatus.IN_USE)
  ) {
    // If there is a claim associated with this machine & a cycleTime exists, let the subscription users know about the timing
    const lastAvailableTime = machine.lastAvailableTime
      ? machine.lastAvailableTime.getTime()
      : Date.now();
    const expectedEndTime = lastAvailableTime + machine.claim.cycleTime * 60000;
    const minutesLeft = Math.ceil((expectedEndTime - Date.now()) / 60000);
    cycleTimeInfo = `Expected to finish in approx. ${minutesLeft} minutes. `;
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
  if (fcmToken.startsWith("web_")) {
    // just return as we use web_ prefix to indicate web clients, which don't need this notification
    return;
  }
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

    notification: {
      title: `Reminder: ${machine.name}`,
      body: `Please clear your clothes from ${machine.name} (${machine.room.name} @ ${machine.room.area.shortName || machine.room.area.name})`,
    },

    android: {
      priority: "high",
      notification: {
        channelId: "poke",
        priority: "high",
      },
    },

    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
      headers: {
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-topic": IOS_APP_BUNDLE_ID,
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
  } catch (e: any) {
    console.error("[🔥🏠] Error sending Poke message:", e);

    // Check if the error is due to an invalid/unregistered token
    if (e.code === "messaging/registration-token-not-registered") {
      console.log(
        "[🔥🏠] Token no longer registered for poke, will be cleaned up:",
        fcmToken,
      );
      // Return the error info so the caller can handle cleanup
      return { error: "token-not-registered", fcmToken };
    }

    throw e;
  }
};
