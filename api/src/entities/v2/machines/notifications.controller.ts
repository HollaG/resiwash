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
import { sendPokeNotification } from "../../../utils/firebase-messaging";
import { Machine } from "../../../models/Machine";

interface ClaimMachineRequest {
  fcmToken: string;
  cycleTime: number; // minutes
}

// TEMPORARY IN MEMORY MAP

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
      const machine = await AppDataSource.getRepository(Machine).findOneBy({
        machineId: parseInt(machineId),
      });

      if (!machine) {
        return sendErrorResponse(res, "Machine not found", 404);
      }

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
        } catch (error: any) {
          console.error(error);
          return sendErrorResponse(res, error.message, 400);
        }
      }

      // now, claim the machine
      _claimMachine(machineId, fcmToken, cycleTime);

      machine.currentCycleTime = cycleTime;
      await AppDataSource.getRepository(Machine).save(machine);

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
      _unclaimMachine(machineId, fcmToken);

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

      if (!canPoke(machineId)) {
        return sendErrorResponse(res, "Poke cooldown active", 400);
      }

      // now, poke the claimant
      const claimants = getClaimants(machineId);

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

      // now, claim the machine
      _claimMachine(machineId, fcmToken, cycleTime);

      sendOkResponse(res, { message: "Machine claimed successfully" });
    } catch (error) {
      return sendErrorResponse(res, error.message, 400);
    }
  },
);
