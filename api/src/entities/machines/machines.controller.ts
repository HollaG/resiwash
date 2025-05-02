import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import { Machine } from "../../models/Machine";
import { MachineType } from "../../core/types";

export const getMachines = asyncHandler(async (req: Request, res: Response) => {
  const areaId = req.params.areaId;
  const roomId = req.params.roomId;

  const machineRepository = AppDataSource.getRepository(Machine);
  // only rooms with :areaId
  if (!areaId || Number(areaId) <= 0) {
    console.log("getRooms: areaId is not valid", areaId);
    return sendErrorResponse(res, "Area ID is required", 400);
  }

  const machines = await machineRepository.find({
    where: {
      room: {
        roomId: Number(roomId), //
      },
    },
    // relations: ["room"], // include this if you want the full Area object loaded too
  });

  sendOkResponse(res, machines);
});

export const createMachine = async (req: Request, res: Response) => {
  const areaId = req.params.areaId;
  const roomId = req.params.roomId;
  // expected fields: name, label, type
  // optional fields: imageUrl

  // todo: authentication and authorization

  console.log("createMachine", req.body);

  const { name, label, type, imageUrl } = req.body;

  if (!name) {
    return sendErrorResponse(res, "Name is required", 400);
  }
  if (!roomId || Number(roomId) <= 0) {
    return sendErrorResponse(res, "Area ID is required", 400);
  }
  if (!type) {
    return sendErrorResponse(res, "Type is required", 400);
  }

  // type must be one of the MachineType enum values
  if (!Object.values(MachineType).includes(type)) {
    return sendErrorResponse(res, "Type is not valid", 400);
  }

  const machine = new Machine();
  machine.name = name;
  machine.label = label || null;
  machine.type = type || null;
  machine.imageUrl = imageUrl || null;
  machine.room = { roomId: Number(roomId) } as any; // type assertion to satisfy TypeScript

  const machineRepository = AppDataSource.getRepository(Machine);
  await machineRepository.save(machine);

  sendOkResponse(res, machine);
};

export const getOneMachine = asyncHandler(
  async (req: Request, res: Response) => {
    const areaId = req.params.areaId;
    const roomId = req.params.roomId;
    const machineId = req.params.machineId;

    const machineRepository = AppDataSource.getRepository(Machine);
    // only rooms with :areaId
    if (!areaId || Number(areaId) <= 0) {
      console.log("getRooms: areaId is not valid", areaId);
      return sendErrorResponse(res, "Area ID is required", 400);
    }
    const machineWithEvents = await AppDataSource.getRepository(Machine)
      .createQueryBuilder("machine")
      .leftJoinAndSelect("machine.events", "event")
      .where("machine.machineId = :id", { id: machineId })
      .orderBy("event.timestamp", "DESC") // sort events descending
      .getOne();

    sendOkResponse(res, machineWithEvents);
  }
);
