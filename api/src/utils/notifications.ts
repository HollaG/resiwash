import { Machine } from "../models/Machine";
import { Claim } from "../models/Claim";
import { LastPoke } from "../models/LastPoke";
import { AppDataSource } from "../data-source";
import { sendClaimedMachineStatusChangedNotification } from "./firebase-messaging";

// Important things to decide
// Should we allow multiple users to claim the same machine?
// If we allow multiple users to claim the machine, how do we handle the cycleTime?
// the feature for showing estimated time remaining will take whos cycleTime?

interface IClaimMapEntry {
  fcmToken: string;
  cycleTime: number;
  claimedAt: Date; // for expiration
}

class ClaimError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
  }
}

class NotClaimedError extends ClaimError {
  constructor() {
    super("Machine is not claimed");
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

export const unclaimMachine = async (machineId: string, fcmToken: string) => {
  const claimRepository = AppDataSource.getRepository(Claim);

  const claim = await claimRepository.findOne({
    where: {
      machineId: Number(machineId),
      fcmToken: fcmToken,
    },
  });

  if (claim) {
    await claimRepository.remove(claim);
    console.log(`Unclaimed machine ${machineId} for ${fcmToken}`);
  }
};

/**
 * Claim a machine for a user
 *
 * Note: Multiple users can claim a machine at the same time
 *
 * @param machineId
 * @param fcmToken
 * @param cycleTime
 */
export const claimMachine = async (
  machineId: string,
  fcmToken: string,
  cycleTime: number,
) => {
  const claimRepository = AppDataSource.getRepository(Claim);

  // Check if this user has already claimed this machine
  const existingClaim = await claimRepository.findOne({
    where: {
      machineId: Number(machineId),
      fcmToken: fcmToken,
    },
  });

  if (existingClaim) {
    // already claimed by this user
    console.log(`Machine ${machineId} already claimed by ${fcmToken}`);
    return false; // no error
  }

  // if the user has already claimed another machine, unclaim it
  // const previousClaim = await claimRepository.findOne({
  //   where: {
  //     fcmToken: fcmToken,
  //   },
  // });
  // if (previousClaim) {
  //   // unclaim previous machine
  //   await unclaimMachine(previousClaim.machineId.toString(), fcmToken);
  // }

  const claim = new Claim();
  claim.machineId = Number(machineId);
  claim.fcmToken = fcmToken;
  claim.cycleTime = cycleTime;

  await claimRepository.save(claim);

  console.log(
    `Claimed machine ${machineId} for ${fcmToken} with cycle time ${cycleTime}`,
  );

  return true;
};

export const updateCycleTime = async (
  machineId: string,
  fcmToken: string,
  cycleTime: number,
) => {
  const claimRepository = AppDataSource.getRepository(Claim);

  const claim = await claimRepository.findOne({
    where: {
      machineId: Number(machineId),
      fcmToken: fcmToken,
    },
  });

  if (!claim) {
    throw new NotClaimedError();
  }

  claim.cycleTime = cycleTime;
  await claimRepository.save(claim);

  console.log(
    "Updated cycle time for",
    fcmToken,
    "on machine",
    machineId,
    "to",
    cycleTime,
  );
  return true;
};

export const getClaimants = async (
  machineId: string,
): Promise<IClaimMapEntry[]> => {
  const claimRepository = AppDataSource.getRepository(Claim);

  const claims = await claimRepository.find({
    where: {
      machineId: Number(machineId),
    },
  });

  return claims.map((claim) => ({
    fcmToken: claim.fcmToken,
    cycleTime: claim.cycleTime,
    claimedAt: claim.claimedAt,
  }));
};

export const sendNotificationToClaimants = async (machine: Machine) => {
  const claimants = await getClaimants(machine.machineId.toString());
  console.log(
    `Sending notifications to ${claimants.length} claimants for machine ${machine.machineId}`,
  );

  for (const claimant of claimants) {
    // send notification to claimant.fcmToken
    sendClaimedMachineStatusChangedNotification({
      fcmToken: claimant.fcmToken,
      oldStatus: null,
      newStatus: null,
      machine,
    }).catch((e) => {}); // do nothing
  }
};

export const canPoke = async (machineId: string): Promise<boolean> => {
  const lastPokeRepository = AppDataSource.getRepository(LastPoke);

  const lastPokeRecord = await lastPokeRepository.findOne({
    where: {
      machineId: Number(machineId),
    },
  });

  const now = new Date();

  if (!lastPokeRecord) {
    // Never poked before, create a new record
    const newLastPoke = new LastPoke();
    newLastPoke.machineId = Number(machineId);
    newLastPoke.lastPokeTime = now;
    await lastPokeRepository.save(newLastPoke);

    console.log("[poke] can poke machine:", machineId);
    return true;
  }

  const diffMs = now.getTime() - lastPokeRecord.lastPokeTime.getTime();
  const diffMinutes = diffMs / 60000;

  if (diffMinutes >= 5) {
    // Update the last poke time
    lastPokeRecord.lastPokeTime = now;
    await lastPokeRepository.save(lastPokeRecord);

    console.log("[poke] can poke machine:", machineId);
    return true;
  }

  console.log("[poke] cannot poke machine yet:", machineId);
  return false;
};
