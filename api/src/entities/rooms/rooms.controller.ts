import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { Room } from "../../models/Room";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";

export const getRooms = asyncHandler(async (req: Request, res: Response) => {
  const areaId = req.params.areaId;

  const roomRepository = AppDataSource.getRepository(Room);
  // only rooms with :areaId
  if (!areaId || Number(areaId) <= 0) {
    console.log("getRooms: areaId is not valid", areaId);
    return sendErrorResponse(res, "Area ID is required", 400);
  }
  const rooms = await roomRepository.find({
    where: {
      area: {
        areaId: Number(areaId), // or any areaId you're filtering by
      },
    },
    // relations: ["area"], // include this if you want the full Area object loaded too
  });

  sendOkResponse(res, rooms);
});

export const createRoom = (async (req: Request, res: Response) => {
  const areaId = req.params.areaId;
  // expected fields: name
  // optional fields: location, description, imageUrl, shortName

  // todo: authentication and authorization

  console.log("createRoom", req.body);

  const { name, location, description, imageUrl, shortName } = req.body;

  if (!name) {
    return sendErrorResponse(res, "Name is required", 400);
  }
  if (!areaId || Number(areaId) <= 0) {
    return sendErrorResponse(res, "Area ID is required", 400);
  }

  const room = new Room();
  room.name = name;
  room.location = location || null;
  room.description = description || null;
  room.imageUrl = imageUrl || null;
  room.shortName = shortName || null;
  room.area = { areaId: Number(areaId) } as any; // type assertion to satisfy TypeScript

  const roomRepository = AppDataSource.getRepository(Room);
  await roomRepository.save(room);

  sendOkResponse(res, room);

});

export const deleteRoom = asyncHandler(async (req: Request, res: Response) => {
  const roomId = parseInt(req.params.id, 10);
  if (isNaN(roomId)) {
    return sendErrorResponse(res, "Invalid room ID", 400);
  }

  const roomRepository = AppDataSource.getRepository(Room);
  const room = await roomRepository.findOneBy({ roomId });

  if (!room) {
    return sendErrorResponse(res, "Room not found", 404);
  }

  await roomRepository.remove(room);

  sendOkResponse(res, { message: "Room deleted successfully" });
});
