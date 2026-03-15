import { Machine } from "../models/Machine";
import { Claim } from "../models/Claim";
import { LastPoke } from "../models/LastPoke";
import { AppDataSource } from "../data-source";
import { sendClaimedMachineStatusChangedNotification } from "./firebase-messaging";
import { updateMachineStatusAfterTime } from "../services/machines.service";
import { MachineStatus } from "../core/types";

/**
 * Helper function to send notifications and automatically clean up invalid tokens
 * @param sendFn The notification function to call
 * @param fcmToken The FCM token to send to
 * @param machineId The machine ID for cleanup purposes
 * @returns The response from the notification function
 */
export const sendAndCleanupInvalidToken = async <T>(
  sendFn: () => Promise<T>,
  fcmToken: string,
  machineId: number,
): Promise<T | null> => {
  try {
    const response = await sendFn();

    // Check if token is no longer valid
    if (
      response &&
      typeof response === "object" &&
      "error" in response &&
      (response as any).error === "token-not-registered"
    ) {
      console.log(
        `[sendAndCleanup] Removing invalid token from claims: ${fcmToken}`,
      );
      await unclaimMachine(machineId, fcmToken);
      return null;
    }

    return response;
  } catch (e) {
    console.error(`[sendAndCleanup] Failed to send to ${fcmToken}:`, e);
    throw e;
  }
};

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

export const unclaimMachine = async (machineId: number, fcmToken: string) => {
  const machineRepository = AppDataSource.getRepository(Machine);

  const machine = await machineRepository
    .createQueryBuilder("machine")
    .leftJoinAndSelect("machine.claim", "claim")
    .addSelect("claim.fcmToken")
    .where("machine.machineId = :machineId", { machineId: Number(machineId) })
    .getOne();

  if (machine) {
    const currentClaimToken = machine.claim?.fcmToken;

    console.log(
      `currentClaimToken is ${currentClaimToken}, trying to unclaim with ${fcmToken} for machine ${machineId}`,
    );

    if (!currentClaimToken) {
      console.log(
        `Machine ${machineId} has no active claim when trying to unclaim for ${fcmToken}`,
      );
      return;
    }

    machine.claimId = null; // remove the claim association but leave it in the claim history
    machine.claim = null;

    await machineRepository.save(machine);

    // Always set machine to available when unclaiming.
    // This is because claimed machines will now transition to FINISHED, for both manual and automatic sensors.
    // if (machine.isManualEntry) {
    await updateMachineStatusAfterTime(MachineStatus.AVAILABLE, machineId);
    // }
    console.log(`Unclaimed machine ${machineId} for ${fcmToken}`);
  } else {
    console.log(
      `Machine ${machineId} not found when trying to unclaim for ${fcmToken}`,
    );
  }
};

/**
 * Add a claim to the claim log for future reference.
 *
 * Note: Only one user can claim a machine at one time
 *
 * @param machineId
 * @param fcmToken
 * @param cycleTime
 */
export const addToClaimHistory = async (
  machineId: number,
  fcmToken: string,
  cycleTime: number,
) => {
  const claimRepository = AppDataSource.getRepository(Claim);

  const claim = new Claim();
  claim.machineId = machineId;
  claim.fcmToken = fcmToken;
  claim.cycleTime = cycleTime;

  const savedClaim = await claimRepository.save(claim);

  console.log(
    `Added claim history for machine ${machineId}, token ${fcmToken}, cycle time ${cycleTime}`,
  );
  return savedClaim;
  // // Check if this user has already claimed this machine
  // const existingClaim = await claimRepository.findOne({
  //   where: {
  //     machineId: machineId,
  //     fcmToken: fcmToken,
  //   },
  // });

  // if (existingClaim) {
  //   // already claimed by this user
  //   console.log(`Machine ${machineId} already claimed by ${fcmToken}`);
  //   return false; // no error
  // }

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
};

export const updateCycleTime = async (claimId: number, cycleTime: number) => {
  const claimRepository = AppDataSource.getRepository(Claim);

  const claim = await claimRepository.findOne({
    where: {
      claimId: claimId,
    },
  });

  if (!claim) {
    throw new NotClaimedError();
  }

  claim.cycleTime = cycleTime;
  await claimRepository.save(claim);

  console.log(
    "Updated cycle time for",
    claim.fcmToken, // hidden so undefined
    "on machine",
    claim.machineId,
    "to",
    cycleTime,
  );
  return true;
};

// Note: As of now, there can only be ONE claimant per machine. We will leave the return value
// as an array for future expansion in case we want to allow multiple claimants per machine.
export const getClaimants = async (
  machineId: number,
): Promise<IClaimMapEntry[]> => {
  // remember to add the FCM token
  // first, check for valid machineId in DB
  const machine = await AppDataSource.getRepository(Machine)
    .createQueryBuilder("machine")
    .leftJoinAndSelect("machine.room", "room")
    .leftJoinAndSelect("room.area", "area")
    .leftJoinAndSelect("machine.claim", "claim") // join with Claim to check existing claimants
    .addSelect("claim.fcmToken") // alert(sanity): REMEMBER TO SANTIZE THIS
    .where("machine.machineId = :id", { id: machineId })
    .getOne();

  if (!machine) {
    throw new Error("Machine not found");
  }

  const fcmToken = machine.claim?.fcmToken;

  if (fcmToken) {
    return [
      {
        fcmToken,
        cycleTime: machine.claim.cycleTime || 0,
        claimedAt: machine.claim.claimedAt || new Date(),
      },
    ];
  } else {
    return [];
  }
};

export const sendNotificationToClaimants = async (machineId: number) => {
  const claimants = await getClaimants(machineId);
  console.log(
    `Sending notifications to ${claimants.length} claimants for machine ${machineId}`,
  );

  for (const claimant of claimants) {
    await sendAndCleanupInvalidToken(
      () =>
        sendClaimedMachineStatusChangedNotification({
          fcmToken: claimant.fcmToken,
          machineId: machineId,
        }),
      claimant.fcmToken,
      machineId,
    );
  }
};

export const canPoke = async (machineId: number): Promise<boolean> => {
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
