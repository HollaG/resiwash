import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { Machine } from "../../../models/Machine";
import { GetQueryBoolean, MachineType } from "../../../core/types";
import { UpdateEvent } from "../../../models/UpdateEvent";
import { RawEvent } from "../../../models/RawEvent";

interface GetMachinesRequest {
  areaIds?: string[]; // todo, we don't need to filter by this anyway
  roomIds?: string[];
  min?: GetQueryBoolean; // actually boolean
  machineIds?: string[];
  extra?: GetQueryBoolean; // actually boolean
}

// get all machines. but only
export const getMachines = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetMachinesRequest>,
    res: Response
  ) => {
    console.log("getMachines", req.query);
    const {
      areaIds = [],
      roomIds = [],
      min,
      machineIds = [],
      extra = GetQueryBoolean.FALSE,
    } = req.query;

    let machines =
      AppDataSource.getRepository(Machine).createQueryBuilder("machine");

    if (GetQueryBoolean.parse(extra)) {
      // left join room and area
      console.log("including room and area info");
      machines = machines
        .leftJoinAndSelect("machine.room", "room")
        .leftJoinAndSelect("room.area", "area");
    }

    console.log("SQL Query:", machines.getSql());
    console.log("Query parameters:", machines.getParameters());
    // if (areaId && !Number.isNaN(Number(areaId))) {
    //   machines = machines.where("area.areaId = :areaId", {
    //     areaId: Number(areaId),
    //   });
    // }

    if (roomIds.length > 0) {
      machines = machines.where("machine.roomId IN (:...roomIds)", {
        roomIds: roomIds.map(Number),
      });
    }

    if (machineIds.length > 0) {
      machines =
        roomIds.length > 0
          ? machines.andWhere("machine.machineId IN (:...machineIds)", {
              machineIds: machineIds.map(Number),
            })
          : machines.where("machine.machineId IN (:...machineIds)", {
              machineIds: machineIds.map(Number),
            });
    }

    machines = machines.orderBy("machine.name", "ASC");

    console.log("Final SQL Query:", machines.getSql());
    console.log("Final Query parameters:", machines.getParameters());

    const machinesList = await machines.getMany();

    console.log("Query result count:", machinesList.length);
    console.log({ machinesList });
    sendOkResponse(res, machinesList);

    // // // only rooms with :areaId
    // if (!areaId || Number(areaId) <= 0) {
    //   console.log("getRooms: areaId is not valid", areaId);
    //   return sendErrorResponse(res, "Area ID is required", 400);
    // }

    // const machines = await AppDataSource.getRepository(Machine)
    //   .createQueryBuilder("machine")
    //   .innerJoinAndSelect("machine.room", "room")
    //   .innerJoinAndSelect("room.area", "area")
    //   .where("room.roomId = :roomId", { roomId })
    //   .andWhere("area.areaId = :areaId", { areaId })
    //   .orderBy("machine.name", "ASC")
    //   .getMany();

    // for (const machine of machines) {
    //   const events = await AppDataSource.getRepository(UpdateEvent)
    //     .createQueryBuilder("event")
    //     .where("event.machineId = :id", { id: machine.machineId })
    //     .orderBy("event.timestamp", "DESC")
    //     .take(1)
    //     .getMany();

    //   if (!events || events.length === 0) {
    //     machine.events = [];
    //   } else {
    //     // only take the latest event
    //     const latestEvent = events[0];
    //     machine.events = [latestEvent];
    //   }

    //   // also get the raw events
    //   const rawEvents = await AppDataSource.getRepository(RawEvent)
    //     .createQueryBuilder("event")
    //     .where("event.machineId = :id", { id: machine.machineId })
    //     .orderBy("event.timestamp", "DESC")
    //     .take(1)
    //     .getMany();
    //   if (!rawEvents || rawEvents.length === 0) {
    //     machine.rawEvents = [];
    //   } else {
    //     // only take the latest event
    //     const latestEvent = rawEvents[0];
    //     machine.rawEvents = [latestEvent];
    //   }
    // }

    // // additional fields:
    // // `currentStatus`, `previousStatus`, `events`, `rawEvents`

    // // to display how long ago the machine was in this status, use lastChangeTime
    // // example message: Changed to `${currentStatus}` ${new Date(currentTimestamp).toLocaleTimeString()} ago (from ${previousStatus})
  }
);

interface GetMachineRequest {
  extra?: GetQueryBoolean;
  depth?: number; // for future use, to control how much data to return
}

export const getMachine = asyncHandler(
  async (
    req: Request<{ machineId: string }, unknown, unknown, GetMachineRequest>,
    res: Response
  ) => {
    const machineId = parseInt(req.params.machineId, 10);
    if (isNaN(machineId)) {
      return sendErrorResponse(res, { message: "Invalid machine ID" }, 400);
    }

    const { extra = GetQueryBoolean.FALSE, depth = 0 } = req.query;

    // const machine = await AppDataSource.getRepository(Machine).findOneBy({
    //   machineId,
    // });

    // get machine and join room and area
    let machineQuery =
      AppDataSource.getRepository(Machine).createQueryBuilder("machine");
    if (GetQueryBoolean.parse(extra)) {
      machineQuery = machineQuery
        .leftJoinAndSelect("machine.room", "room")
        .leftJoinAndSelect("room.area", "area");
    }

    const machine = await machineQuery
      .where("machine.machineId = :id", { id: machineId })
      .getOne();

    if (!machine) {
      return sendErrorResponse(res, { message: "Machine not found" }, 404);
    }

    const events = await AppDataSource.getRepository(UpdateEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machineId })
      .orderBy("event.timestamp", "DESC")
      .take(10)
      .getMany();

    const rawEvents = await AppDataSource.getRepository(RawEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machineId })
      .orderBy("event.timestamp", "DESC")
      .take(1000)
      .getMany();

    machine.events = events;
    machine.rawEvents = rawEvents;

    sendOkResponse(res, machine);
  }
);

export const createMachine = async (req: Request, res: Response) => {
  // expected fields: name, label, type
  // optional fields: imageUrl

  // todo: authentication and authorization

  console.log("createMachine", req.body);

  const { areaId, roomId, machine: machineToCreate } = req.body;
  const { name, label, type, imageUrl } = machineToCreate;

  if (!name) {
    return sendErrorResponse(res, { message: "Name is required" }, 400);
  }
  if (!roomId || Number(roomId) <= 0) {
    return sendErrorResponse(res, { message: "Room ID is required" }, 400);
  }
  if (!type) {
    return sendErrorResponse(res, { message: "Type is required" }, 400);
  }

  // type must be one of the MachineType enum values
  if (!Object.values(MachineType).includes(type)) {
    return sendErrorResponse(res, { message: "Type is not valid" }, 400);
  }

  const machine = new Machine();
  machine.name = name;
  machine.label = label || null;
  machine.type = type || null;
  machine.imageUrl = imageUrl || null;
  machine.roomId = Number(roomId);

  const machineRepository = AppDataSource.getRepository(Machine);
  await machineRepository.save(machine);

  sendOkResponse(res, machine);
};

export const deleteMachine = asyncHandler(
  async (req: Request, res: Response) => {
    const machineId = parseInt(req.params.machineId, 10);
    if (isNaN(machineId)) {
      return sendErrorResponse(res, { message: "Invalid machine ID" }, 400);
    }

    const machineRepository = AppDataSource.getRepository(Machine);
    const machine = await machineRepository.findOneBy({ machineId });

    if (!machine) {
      return sendErrorResponse(res, { message: "Machine not found" }, 404);
    }

    await machineRepository.remove(machine);

    sendOkResponse(res, { message: "Machine deleted successfully" });
  }
);

export const updateMachine = asyncHandler(
  async (req: Request, res: Response) => {
    const machineId = parseInt(req.params.machineId, 10);
    if (isNaN(machineId)) {
      return sendErrorResponse(res, { message: "Invalid machine ID" }, 400);
    }

    const { machine: machineToUpdate } = req.body as { machine: Machine };

    const { name, label, type, imageUrl } = machineToUpdate;

    if (!name) {
      return sendErrorResponse(res, { message: "Name is required" }, 400);
    }
    if (!type) {
      return sendErrorResponse(res, { message: "Type is required" }, 400);
    }

    // type must be one of the MachineType enum values
    if (!Object.values(MachineType).includes(type)) {
      return sendErrorResponse(res, { message: "Type is not valid" }, 400);
    }

    const machineRepository = AppDataSource.getRepository(Machine);
    const machine = await machineRepository.findOneBy({ machineId });

    if (!machine) {
      return sendErrorResponse(res, { message: "Machine not found" }, 404);
    }

    machine.name = name;
    machine.label = label || null;
    machine.type = type || null;
    machine.imageUrl = imageUrl || null;

    await machineRepository.save(machine);

    sendOkResponse(res, machine);
  }
);
