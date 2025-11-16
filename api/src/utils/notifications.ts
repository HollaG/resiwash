import { Machine } from "../models/Machine";
import { sendClaimedMachineStatusChangedNotification } from "./firebase-messaging";

interface IClaimMapEntry {
  fcmToken: string;
  cycleTime: number;
  claimedAt: Date; // for expiration
}

const ClaimMap: {
  [machineId: string]: IClaimMapEntry[];
} = {};

const UserMap: {
  [fcmToken: string]: string[]; // machineId
} = {};

const LastPokeTimeMap: {
  [machineId: string]: Date;
} = {};

const ClaimedUsers = new Set<string>();

class ClaimError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
  }
}

// machine already claimed by someone else
// class AlreadyClaimedError extends ClaimError {
//   constructor() {
//     super("Machine is already claimed by another user");
//   }
// }

// this user has already claimed another machine
// class AlreadyClaimedSomethingElseError extends ClaimError {
//   constructor() {
//     super("You have already claimed another machine");
//   }
// }

export const unclaimMachine = (machineId: string, fcmToken: string) => {
  if (!ClaimMap[machineId]) {
    return;
  }

  ClaimMap[machineId] = ClaimMap[machineId].filter(
    (claim) => claim.fcmToken !== fcmToken
  );
  UserMap[fcmToken] = UserMap[fcmToken].filter((id) => id !== machineId);

  console.log("Current ClaimMap:", ClaimMap);
  console.log("Current UserMap:", UserMap);
};

/**
 * Claim a machine for a user
 *
 * Note: only one user can claim a machine at a time
 * Note: only one machine can be claimed by a user at a time
 *
 * @param machineId
 * @param fcmToken
 * @param cycleTime
 */
export const claimMachine = (
  machineId: string,
  fcmToken: string,
  cycleTime: number
) => {
  const claimedAt = new Date();
  // const expirationTime = new Date(claimedAt.getTime() + cycleTime * 60000);

  if (!ClaimMap[machineId]) {
    ClaimMap[machineId] = [];
  }
  if (!UserMap[fcmToken]) {
    UserMap[fcmToken] = [];
  }

  if (ClaimMap[machineId].some((claim) => claim.fcmToken === fcmToken)) {
    // already claimed by this user
    return; // no error
  }

  // if the user has already claimed another machine, unclaim it
  // const previousMachineId = UserMap[fcmToken];
  // if (previousMachineId) {
  //   // unclaim previous machine
  //   unclaimMachine(previousMachineId, fcmToken);
  // }

  ClaimMap[machineId].push({ fcmToken, cycleTime, claimedAt });

  UserMap[fcmToken].push(machineId);

  console.log("Current ClaimMap:", ClaimMap);
  console.log("Current UserMap:", UserMap);

  // Set a timeout to remove the claim after the expiration time
  // setTimeout(() => {
  //   ClaimMap[machineId] = ClaimMap[machineId].filter(claim => claim.fcmToken !== fcmToken);
  // }, expirationTime.getTime() - claimedAt.getTime());
};

export const getClaimants = (machineId: string): IClaimMapEntry[] => {
  if (!ClaimMap[machineId]) {
    return [];
  }

  return ClaimMap[machineId];
};

export const sendNotificationToClaimants = async (machine: Machine) => {
  const claimants = getClaimants(machine.machineId.toString());
  console.log("current ClaimMap:", ClaimMap);
  for (const claimant of claimants) {
    // send notification to claimant.fcmToken
    // check the last poke time

    sendClaimedMachineStatusChangedNotification({
      fcmToken: claimant.fcmToken,
      oldStatus: null,
      newStatus: null,
      machine,
    }).catch((e) => {}); // do nothing
  }
};

export const canPoke = (machineId: string): boolean => {
  const lastPokeTime = LastPokeTimeMap[machineId];
  if (!lastPokeTime) {
    LastPokeTimeMap[machineId] = new Date();
    console.log("[poke] can poke machine:", machineId);
    return true; // never poke before
  }
  const now = new Date();
  const diffMs = now.getTime() - lastPokeTime.getTime();
  const diffMinutes = diffMs / 60000;
  if (diffMinutes >= 5) {
    LastPokeTimeMap[machineId] = now;
    console.log("[poke] can poke machine:", machineId);
    return true;
  }
  console.log("[poke] cannot poke machine yet:", machineId);
  return false;
};
