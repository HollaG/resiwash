import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import { Machine } from "../../models/Machine";
import { MachineType } from "../../core/types";
import { UpdateEvent } from "../../models/UpdateEvent";
import { RawEvent } from "../../models/RawEvent";

// get all machines. but only
export const getMachines = asyncHandler(async (req: Request, res: Response) => {
  console.log("getMachines", req.params);
  const areaId = req.params.areaId;
  const roomId = req.params.roomId;

  // only rooms with :areaId
  if (!areaId || Number(areaId) <= 0) {
    console.log("getRooms: areaId is not valid", areaId);
    return sendErrorResponse(res, "Area ID is required", 400);
  }

  // const machines = await AppDataSource.getRepository(Machine)
  //   .createQueryBuilder("machine")
  //   .innerJoinAndSelect("machine.room", "room")
  //   .innerJoinAndSelect("room.area", "area")
  //   .where("room.roomId = :roomId", { roomId })
  //   .andWhere("area.areaId = :areaId", { areaId })
  //   .orderBy("machine.name", "ASC")
  //   .getMany();

  // // const evE );

  // // each machine should only have the latest event (this prevents information overload)
  // // assert: `machines.events` should be length 0 or 1

  // console.log("getMachines", machines);
  // const result = []

  const result = await AppDataSource.createQueryRunner().query(
    `
  WITH ranked_events AS (
    SELECT
      "machineId",
      "statusCode",
      "timestamp",
      ROW_NUMBER() OVER (PARTITION BY "machineId" ORDER BY "timestamp" DESC) AS rank
    FROM "update_event"
  )
  SELECT
    m.*,
    current."statusCode" AS "currentStatus",
    previous."statusCode" AS "previousStatus",
    current."timestamp" AS "currentTimestamp",
    room."roomId",
    room."areaId"
  FROM "machine" m
  LEFT JOIN ranked_events current
    ON m."machineId" = current."machineId" AND current.rank = 1
  LEFT JOIN ranked_events previous
    ON m."machineId" = previous."machineId" AND previous.rank = 2
  LEFT JOIN "room"
    ON m."roomId" = room."roomId"
  WHERE room."areaId" = $1 AND room."roomId" = $2
  `,
    [areaId, roomId]
  );

  for (const machine of result) {
    const events = await AppDataSource.getRepository(UpdateEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machine.machineId })
      .orderBy("event.timestamp", "DESC")
      .take(1)
      .getMany();

    if (!events || events.length === 0) {
      machine.events = [];
    } else {
      // only take the latest event
      const latestEvent = events[0];
      machine.events = [latestEvent];
    }

    // also get the raw events
    const rawEvents = await AppDataSource.getRepository(RawEvent)
      .createQueryBuilder("event")
      .where("event.machineId = :id", { id: machine.machineId })
      .orderBy("event.timestamp", "DESC")
      .take(1)
      .getMany();
    if (!rawEvents || rawEvents.length === 0) {
      machine.rawEvents = [];
    } else {
      // only take the latest event
      const latestEvent = rawEvents[0];
      machine.rawEvents = [latestEvent];
    }
  }

  // additional fields:
  // `currentStatus`, `previousStatus`, `events`, `rawEvents`

  // to display how long ago the machine was in this status, use lastChangeTime
  // example message: Changed to `${currentStatus}` ${new Date(currentTimestamp).toLocaleTimeString()} ago (from ${previousStatus})

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
    return sendErrorResponse(res, "Room ID is required", 400);
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

export const deleteMachine = asyncHandler(
  async (req: Request, res: Response) => {
    const areaId = req.params.areaId;
    const roomId = req.params.roomId;
    const machineId = parseInt(req.params.machineId, 10);
    if (isNaN(machineId)) {
      return sendErrorResponse(res, "Invalid machine ID", 400);
    }

    const machineRepository = AppDataSource.getRepository(Machine);
    const machine = await machineRepository.findOneBy({ machineId });

    if (!machine) {
      return sendErrorResponse(res, "Machine not found", 404);
    }

    await machineRepository.remove(machine);

    sendOkResponse(res, { message: "Machine deleted successfully" });
  }
);
