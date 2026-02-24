import expressAsyncHandler from "express-async-handler";
import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { setMachineManualStatus } from "../../../services/machines.service";
import { MachineStatus } from "../../../core/types";

import {
  addToClaimHistory,
  unclaimMachine as _unclaimMachine,
  canPoke,
  getClaimants,
  sendAndCleanupInvalidToken,
} from "../../../utils/notifications";
import {
  sendClaimedMachineStatusChangedNotification,
  sendMachineGroupStatusChangedNotification,
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
      const { machineId } = req.params;
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
        .addSelect("machine.currentClaimantToken") // alert(sanity): REMEMBER TO SANTIZE THIS
        .where("machine.machineId = :id", { id: parseInt(machineId, 10) })
        .getOne();

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

      if (
        machine.currentClaimantToken &&
        machine.currentClaimantToken !== fcmToken &&
        machine.currentStatus !== MachineStatus.AVAILABLE
      ) {
        // not allowed to claim if there's already a claimant and it's not the same user, and the machine is not available.
        return sendErrorResponse(
          res,
          "Machine is already claimed by another user",
          400,
        );
      }
      // allowed to claim

      // 1. update the machine object with the new claimant and cycle time
      machine.currentClaimantToken = fcmToken;
      machine.currentCycleTime = cycleTime;
      await AppDataSource.getRepository(Machine).save(machine);

      // 2. update the claims table with the new claim
      await addToClaimHistory(machineId, fcmToken, cycleTime);

      // if the machine is manual mode, we also need to set the status
      console.log({ machine });
      if (machine.isManualEntry) {
        try {
          console.log("Setting initial IN_USE status for manual machine claim");

          

          await setMachineManualStatus({
            machineId: machine.machineId,
            status: MachineStatus.IN_USE,
            cycleTime,
          });

          console.log(
            `Machine ${machineId} already claimed by ${fcmToken}, not setting status to IN_USE again`,
          );
          // return sendErrorResponse(res, "Machine already claimed by this user", 400);
          sendAndCleanupInvalidToken(
            () =>
              sendClaimedMachineStatusChangedNotification({
                machine,
                fcmToken,
              }),
            fcmToken,
            machineId,
          );

          // notify all listeners
          sendMachineGroupStatusChangedNotification({
            machine,
          })
          

        } catch (error: any) {
          console.error(error);
          return sendErrorResponse(res, error.message, 400);
        }
      }

      // now, send a notification to the user
      // sendClaimedMachineStatusChangedNotification({ machine, fcmToken });

      sendOkResponse(res, { message: "Machine claimed successfully" });
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
      const { machineId } = req.params;
      const { fcmToken } = req.body as UnclaimMachineRequest;

      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository("Machine").findOneBy({
        machineId: parseInt(machineId),
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
      const { machineId } = req.params;

      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository(Machine).findOne({
        where: { machineId: parseInt(machineId) },
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

export const updateClaimCycle = expressAsyncHandler(
  async (req: Request, res: Response) => {
    try {
      const { machineId } = req.params;
      const { fcmToken, cycleTime } = req.body as ClaimMachineRequest;

      // first, check for valid machineId in DB
      const machine = await AppDataSource.getRepository("Machine").findOneBy({
        machineId: parseInt(machineId),
      });

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

      // now, update the claim cycle time
      await addToClaimHistory(machineId, fcmToken, cycleTime);

      sendOkResponse(res, { message: "Claim cycle updated successfully" });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);
