import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import { Machine } from "../../models/Machine";
import { MachineType } from "../../core/types";
import { UpdateEvent } from "../../models/UpdateEvent";
import { RawEvent } from "../../models/RawEvent";

export const getMachines = asyncHandler(async (req: Request, res: Response) => {
  const areaId = req.params.areaId;
  const roomId = req.params.roomId;

  // only rooms with :areaId
  if (!areaId || Number(areaId) <= 0) {
    console.log("getRooms: areaId is not valid", areaId);
    return sendErrorResponse(res, "Area ID is required", 400);
  }

  const machines = await AppDataSource.getRepository(Machine)
    .createQueryBuilder("machine")
    .innerJoinAndSelect("machine.room", "room")
    .innerJoinAndSelect("room.area", "area")
    .where("room.roomId = :roomId", { roomId })
    .andWhere("area.areaId = :areaId", { areaId })
    .orderBy("machine.name", "ASC")
    .getMany();

  // const evE );

  // each machine should only have the latest event (this prevents information overload)
  // assert: `machines.events` should be length 0 or 1

  const result = []
  for (const machine of machines) {
    const events = await AppDataSource.getRepository(UpdateEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machine.machineId })
      .orderBy("event.timestamp", "DESC")
      .take(1)
      .getMany();


    if (!events || events.length === 0) {
      machine.events = []
    } else {
      // only take the latest event
      const latestEvent = events[0];
      machine.events = [latestEvent];
    }

    result.push({
      status: machine.events.length > 0 ? machine.events[0].statusCode : -1,
      machine
    })
  }





  sendOkResponse(res, result);
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
    const machineId = Number(req.params.machineId);

    const showRaw = req.query.raw === "true" ? true : false;

    // only rooms with :areaId
    if (!areaId || Number(areaId) <= 0) {
      console.log("getRooms: areaId is not valid", areaId);
      return sendErrorResponse(res, "Area ID is required", 400);
    }
    const machine = await AppDataSource.getRepository(Machine).findOneBy({
      machineId,
    });

    if (!machine) {
      return sendErrorResponse(res, "Machine not found", 404);
    }



    const events = await AppDataSource.getRepository(UpdateEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machineId })
      .orderBy("event.timestamp", "DESC")
      .take(100)
      .getMany();

    const rawEvents = await AppDataSource.getRepository(RawEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machineId })
      .orderBy("event.timestamp", "DESC")
      .take(1000)
      .getMany();

    machine.events = events;
    machine.rawEvents = rawEvents;

    let status = null;
    if (events.length > 0) {
      status = events[0].statusCode;
    } else {
      status = -1;
    }

    sendOkResponse(res, {
      status,
      machine,
    });
  }
);
