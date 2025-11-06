interface IClaimMapEntry {
  fcmToken: string;
  cycleTime: number;
  claimedAt: Date; // for expiration
}

const ClaimMap: {
  [machineId: string]: IClaimMapEntry[];
} = {}

const UserMap: {
  [fcmToken: string]: string; // machineId
} = {}

const ClaimedUsers = new Set<string>();

class ClaimError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
  }
}

// machine already claimed by someone else
class AlreadyClaimedError extends ClaimError {
  constructor() {
    super("Machine is already claimed by another user");
  }
}

// this user has already claimed another machine
class AlreadyClaimedSomethingElseError extends ClaimError {
  constructor() {
    super("You have already claimed another machine");
  }
}

export const unclaimMachine = (machineId: string, fcmToken: string) => {
  if (!ClaimMap[machineId]) {
    return;
  }

  // ClaimMap[machineId] = ClaimMap[machineId].filter(claim => claim.fcmToken !== fcmToken);
  ClaimMap[machineId] = []
  delete UserMap[fcmToken];
  // ClaimedUsers.delete(fcmToken);


  console.log("Current ClaimMap:", ClaimMap);
  console.log("Current UserMap:", UserMap);

}


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
export const claimMachine = (machineId: string, fcmToken: string, cycleTime: number) => {
  const claimedAt = new Date();
  // const expirationTime = new Date(claimedAt.getTime() + cycleTime * 60000);

  if (!ClaimMap[machineId]) {
    ClaimMap[machineId] = [];
  }

  if (ClaimMap[machineId].some(claim => claim.fcmToken === fcmToken)) {
    // already claimed by this user
    return; // no error
  }

  if (ClaimMap[machineId].length > 0) {
    // already claimed by another user
    throw new AlreadyClaimedError();
  }

  // if (ClaimedUsers.has(fcmToken)) {
  //   // this user has already claimed another machine
  //   throw new AlreadyClaimedSomethingElseError();
  // }
  // ClaimedUsers.add(fcmToken);

  const previousMachineId = UserMap[fcmToken];
  if (previousMachineId) {
    // unclaim previous machine
    unclaimMachine(previousMachineId, fcmToken);
  }

  ClaimMap[machineId].push({ fcmToken, cycleTime, claimedAt });
  UserMap[fcmToken] = machineId;

  console.log("Current ClaimMap:", ClaimMap);
  console.log("Current UserMap:", UserMap);

  // Set a timeout to remove the claim after the expiration time
  // setTimeout(() => {
  //   ClaimMap[machineId] = ClaimMap[machineId].filter(claim => claim.fcmToken !== fcmToken);
  // }, expirationTime.getTime() - claimedAt.getTime());
}



export const getClaimants = (machineId: string): IClaimMapEntry[] => {
  if (!ClaimMap[machineId]) {
    return [];
  }

  return ClaimMap[machineId];
}