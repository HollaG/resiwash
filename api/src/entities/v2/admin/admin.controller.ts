import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { sendMachineGroupStatusChangedNotification } from "../../../utils/firebase-messaging";
import { Machine } from "../../../models/Machine";
import { AppDataSource } from "../../../data-source";

type DebugNotificationRequest = {
  machineId: number;
  oldStatus: string;
  newStatus: string;

  password: string;
};
export const sendDebugNotification = asyncHandler(async (req: Request<{}, {}, DebugNotificationRequest>, res: Response) => {
  // return empty for now, not implemented

  const { machineId: _machineId, oldStatus, newStatus, password } = req.body;

  const machineId = parseInt(_machineId.toString(), 10);
  if (isNaN(machineId)) {
    return sendErrorResponse(res, "Invalid machine ID", 400);
  }


  if (password !== process.env.DEBUG_PASSWORD) {
    return sendErrorResponse(res, "Unauthorized", 401);
  }

  // get the machine with room and area
  const machineRepository = AppDataSource.getRepository(Machine);
  const machine = await machineRepository.findOne({
    where: { machineId },
    relations: ["room", "room.area"],
  });

  if (!machine) {
    return sendErrorResponse(res, "Machine not found", 404);
  }

  console.log({ machine })
  const result = await sendMachineGroupStatusChangedNotification({
    machineId,

  });


  sendOkResponse(res, { result });
});