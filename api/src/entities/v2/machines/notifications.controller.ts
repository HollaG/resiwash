import expressAsyncHandler from "express-async-handler";
import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { setMachineManualStatusAndNotify } from "../../../services/machines.service";
import { isAvailableLike, MachineStatus } from "../../../core/types";

import {
  addToClaimHistory,
  unclaimMachine as _unclaimMachine,
  canPoke,
  getClaimants,
  sendAndCleanupInvalidToken,
  updateCycleTime,
} from "../../../utils/notifications";
import {
  DataMessageForDeviceTimers,
  sendClaimedMachineStatusChangedNotification,
  sendMachineGroupStatusChangedNotification,
  sendNewlyClaimedMachineNotification,
  sendPokeNotification,
} from "../../../utils/firebase-messaging";
import { Machine } from "../../../models/Machine";

interface ClaimMachineRequest {
  fcmToken: string;
  cycleTime: number; // minutes
}

export const claimMachine = expressAsyncHandler(
  async (
    req: Request<{ machineId: string }, unknown, unknown, ClaimMachineRequest>,
    res: Response,
  ) => {
    try {
      const { machineId: _machineId } = req.params;
      const machineId = parseInt(_machineId, 10);
      if (isNaN(machineId)) {
        return sendErrorResponse(res, "Invalid machine ID", 400);
      }
      const { fcmToken, cycleTime } = req.body as ClaimMachineRequest;

      console.log("Claim request received:", {
        machineId,
        fcmToken,
        cycleTime,
      });

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
        return sendErrorResponse(res, "Machine not found", 404);
      }

      if (
        machine.claim &&
        machine.claim.fcmToken !== fcmToken &&
        !isAvailableLike(machine.currentStatus)
      ) {
        // not allowed to claim if there's already a claimant and it's not the same user, and the machine is not available.
        return sendErrorResponse(
          res,
          "Machine is already claimed by another user",
          400,
        );
      }
      // allowed to claim, aka either there's no claimant, or the claimant is the same user, or the machine is available (claimed but not in use)

      // 1. create an entry in the claim history table
      const savedClaim = await addToClaimHistory(
        machineId,
        fcmToken,
        cycleTime,
      );
      // 1. update the machine object with the new claimant and cycle time
      machine.claimId = savedClaim.claimId; // associate the machine with the new claim
      await AppDataSource.getRepository(Machine).save(machine);

      // 2. update the claims table with the new claim

      // if the machine is manual mode, we also need to set the status
      if (machine.isManualEntry) {
        try {
          console.log("Setting initial IN_USE status for manual machine claim");

          await setMachineManualStatusAndNotify({
            machineId: machine.machineId,
            status: MachineStatus.IN_USE,
            cycleTime,
          });

          // return sendErrorResponse(res, "Machine already claimed by this user", 400);
        } catch (error: any) {
          console.error(error);
          return sendErrorResponse(res, error.message, 400);
        }
      } else {
        // notify the user

        await sendAndCleanupInvalidToken(
          () => sendNewlyClaimedMachineNotification({ machineId, fcmToken }),
          fcmToken,
          machineId,
        );
      }

      // * Important note: this machine here is stale.
      // For manual machines, we override all logic below later.
      // But, if it's not a manual machine, then the status of the machine will still be based off the sensor data.
      let secondsTillCompletion = null;
      if (
        isAvailableLike(machine.currentStatus) ||
        machine.currentStatus === MachineStatus.UNKNOWN
      ) {
        const expectedEndTime =
          Date.now() + (cycleTime ? cycleTime * 60000 : 0);

        secondsTillCompletion = Math.floor(
          (expectedEndTime - Date.now()) / 1000,
        );
      } else if (machine.currentStatus === MachineStatus.IN_USE) {
        const expectedEndTime =
          machine.lastAvailableTime!.getTime() +
          (cycleTime ? cycleTime * 60000 : 0);

        secondsTillCompletion = Math.floor(
          (expectedEndTime - Date.now()) / 1000,
        );
      } else if (machine.currentStatus === MachineStatus.FINISHING) {
        const expectedEndTime =
          machine.lastAvailableTime!.getTime() +
          (cycleTime ? cycleTime * 60000 : 0);
        secondsTillCompletion = Math.floor(
          (expectedEndTime - Date.now()) / 1000,
        );
      }

      if (machine.isManualEntry) {
        secondsTillCompletion = cycleTime * 60; // for manual machines, we trust the user's input cycle time
      }

      let data: DataMessageForDeviceTimers = {
        title: `${machine.name} @ ${machine.room?.shortName || machine.room?.name}`,
        body: "",
        secondsTillCompletion, // convert minutes to seconds
        machineId: machine.machineId,
        machineName: machine.name,
        machineRoomName: machine.room?.shortName || machine.room?.name || "",
        machineType: machine.type,
      };

      sendOkResponse(res, { message: "Machine claimed successfully", data });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);

interface UnclaimMachineRequest {
  fcmToken: string;
}

// Unpair a FCM token fro ma machine. Note: also reset the machine status back to available, if it is NOT available (ONLY for Manual machines)
export const unclaimMachine = expressAsyncHandler(
  async (req: Request, res: Response) => {
    try {
      const { machineId: _machineId } = req.params;
      const machineId = parseInt(_machineId, 10);
      if (isNaN(machineId)) {
        return sendErrorResponse(res, "Invalid machine ID", 400);
      }
      const { fcmToken } = req.body as UnclaimMachineRequest;

      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository(Machine).findOneBy({
        machineId: machineId,
      });

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

      // now, unclaim the machine
      await _unclaimMachine(machineId, fcmToken);

      sendOkResponse(res, { message: "Machine unclaimed successfully" });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);

export const pokeClaimant = expressAsyncHandler(
  async (req: Request, res: Response) => {
    try {
      const { machineId: _machineId } = req.params;
      const machineId = parseInt(_machineId, 10);

      if (isNaN(machineId)) {
        return sendErrorResponse(res, "Invalid machine ID", 400);
      }
      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository(Machine).findOne({
        where: { machineId: machineId },
        relations: ["room", "room.area"],
      });

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

      if (!(await canPoke(machineId))) {
        return sendErrorResponse(res, "Poke cooldown active", 400);
      }

      // now, poke the claimant
      const claimants = await getClaimants(machineId);

      if (claimants.length === 0) {
        return sendErrorResponse(res, "No claimants to poke", 400);
      } else {
        // it's a length-1 array
        // const claimant = claimants[0];

        // await sendPokeNotification(machine, claimant.fcmToken);

        for (const claimant of claimants) {
          await sendAndCleanupInvalidToken(
            () => sendPokeNotification(machine, claimant.fcmToken),
            claimant.fcmToken,
            machineId,
          );
        }

        return sendOkResponse(res, { message: "Poke sent successfully" });
      }
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);

export const updateClaimCycleHandler = expressAsyncHandler(
  async (req: Request, res: Response) => {
    try {
      const { machineId: _machineId } = req.params;
      const machineId = parseInt(_machineId, 10);
      if (isNaN(machineId)) {
        return sendErrorResponse(res, "Invalid machine ID", 400);
      }
      const { fcmToken, cycleTime } = req.body as ClaimMachineRequest;

      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository(Machine)
        .createQueryBuilder("machine")
        .leftJoinAndSelect("machine.room", "room")
        .leftJoinAndSelect("room.area", "area")
        .leftJoinAndSelect("machine.claim", "claim") // join with Claim to check existing claimants
        .addSelect("claim.fcmToken") // alert(sanity): REMEMBER TO SANTIZE THIS
        .where("machine.machineId = :id", { id: machineId })
        .where("claim.fcmToken = :fcmToken", { fcmToken })
        .getOne();

      if (!machine) {
        return sendErrorResponse(
          res,
          "Machine not found or you have not claimed this machine",
          404,
        );
      }

      // update the claim cycle time in the claim history table
      await updateCycleTime(machine.claimId, cycleTime);

      // notify claimaints
      const claimants = await getClaimants(machineId);

      for (const claimant of claimants) {
        await sendAndCleanupInvalidToken(
          () =>
            sendClaimedMachineStatusChangedNotification({
              machineId,
              fcmToken: claimant.fcmToken,
            }),
          claimant.fcmToken,
          machineId,
        );
      }

      // now, update the claim cycle time
      // await addToClaimHistory(machineId, fcmToken, cycleTime);

      sendOkResponse(res, { message: "Claim cycle updated successfully" });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);
