import expressAsyncHandler from "express-async-handler";
import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { setMachineManualStatus } from "../../../services/machines.service";
import { MachineStatus } from "../../../core/types";

import {
  claimMachine as _claimMachine,
  unclaimMachine as _unclaimMachine,
  canPoke,
  getClaimants,
} from "../../../utils/notifications";
import {
  sendClaimedMachineStatusChangedNotification,
  sendPokeNotification,
} from "../../../utils/firebase-messaging";
import { Machine } from "../../../models/Machine";

interface ClaimMachineRequest {
  fcmToken: string;
  cycleTime: number; // minutes
}

// If a user tries to claim a machine that has already been claimed,
// we will just update the claim to the new user. This is because the most likely scenario is that someone claimed a machine by accident, and they will want to claim it for real right after. It's less likely that someone will maliciously claim a machine that isn't theirs.
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
      const machine = await AppDataSource.getRepository(Machine).findOne({
        where: { machineId: parseInt(machineId) },
        relations: ["room", "room.area"],
      });

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

      // This has to be set before calling setMachineManualStatus, as re-saving will overwrite any changes made in that function.
      // The `if` block only runs for manual machines. Note that cycleTime is also set in the setMachineManualStatus function,
      // however we still need to set it here as well for non-manual machines.
      // Cycle time is set in the setMachineManualStatus function as it's also used in the API call for manual status updates, from the browser.
      // The browser has no concept of claiming, so we need to set cycle time in both places.
      // TODO: refactor the browser one to use this claimMachine method, and just ignore the fcmToken.
      machine.currentCycleTime = cycleTime;
      await AppDataSource.getRepository(Machine).save(machine);

      // if the machine is manual mode, we also need to set the status
      console.log({ machine });
      if (machine.isManualEntry) {
        try {
          console.log("Setting initial IN_USE status for manual machine claim");

          // claim the machine
          const isFirstClaimaint = await _claimMachine(
            machineId,
            fcmToken,
            cycleTime,
          );
          if (isFirstClaimaint) {
            await setMachineManualStatus({
              machineId: machine.machineId,
              status: MachineStatus.IN_USE,
              cycleTime,
            });
          } else {
            console.log(
              `Machine ${machineId} already claimed by ${fcmToken}, not setting status to IN_USE again`,
            );
            // return sendErrorResponse(res, "Machine already claimed by this user", 400);
            sendClaimedMachineStatusChangedNotification({ machine, fcmToken });
          }
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
          await sendPokeNotification(machine, claimant.fcmToken);
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
      await _claimMachine(machineId, fcmToken, cycleTime);

      sendOkResponse(res, { message: "Claim cycle updated successfully" });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);
