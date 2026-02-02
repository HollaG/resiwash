import { Request, Response } from "express";

import asyncHandler from "express-async-handler";
import { Room } from "../../../models/Room";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";

interface GetRoomsRequest {
  areaIds?: string[];
  roomIds?: string[];
}

export const getRooms = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetRoomsRequest>,
    res: Response
  ) => {
    const { areaIds = [], roomIds = [] } = req.query;

    const roomRepository = AppDataSource.getRepository(Room);
    // only rooms with :areaId
    if (areaIds.length === 0) {
      console.log("getRooms: areaIds is not valid", areaIds);
      return sendErrorResponse(res, { message: "Area ID is required" }, 400);
    }

    let rooms = roomRepository.createQueryBuilder("room");
    if (areaIds.length > 0) {
      rooms = rooms.where("room.areaId IN (:...areaIds)", {
        areaIds: areaIds.map(Number),
      });
    }
    if (roomIds.length > 0) {
      rooms =
        areaIds.length > 0
          ? rooms.andWhere("room.roomId IN (:...roomIds)", {
              roomIds: roomIds.map(Number),
            })
          : rooms.where("room.roomId IN (:...roomIds)", {
              roomIds: roomIds.map(Number),
            });
    }

    const roomList = await rooms.getMany();
    sendOkResponse(res, roomList);
  }
);

export const getRoom = asyncHandler(async (req: Request, res: Response) => {
  const roomId = parseInt(req.params.roomId, 10);
  if (isNaN(roomId)) {
    return sendErrorResponse(res, { message: "Invalid room ID" }, 400);
  }

  const roomRepository = AppDataSource.getRepository(Room);
  const room = await roomRepository.findOneBy({ roomId });

  if (!room) {
    return sendErrorResponse(res, { message: "Room not found" }, 404);
  }

  sendOkResponse(res, room);
});

export const createRoom = async (req: Request, res: Response) => {
  // expected fields: name
  // optional fields: location, description, imageUrl, shortName

  // todo: authentication and authorization

  console.log("createRoom", req.body);

  const { areaId, room: roomToCreate } = req.body as {
    areaId: number;
    room: Room;
  };
  const { name, location, description, imageUrl, shortName } = roomToCreate;

  if (!name) {
    return sendErrorResponse(res, { message: "Name is required" }, 400);
  }
  if (!areaId || Number(areaId) <= 0) {
    return sendErrorResponse(res, { message: "Area ID is required" }, 400);
  }

  const roomRepository = AppDataSource.getRepository(Room);
  const room = roomRepository.create({
    name,
    location: location || null,
    description: description || null,
    imageUrl: imageUrl || null,
    shortName: shortName || null,
    area: { areaId: Number(areaId) },
  });
  await roomRepository.save(room);

  sendOkResponse(res, room);
};

export const deleteRoom = asyncHandler(async (req: Request, res: Response) => {
  const roomId = parseInt(req.params.id, 10);
  if (isNaN(roomId)) {
    return sendErrorResponse(res, { message: "Invalid room ID" }, 400);
  }

  const roomRepository = AppDataSource.getRepository(Room);
  const room = await roomRepository.findOneBy({ roomId });

  if (!room) {
    return sendErrorResponse(res, { message: "Room not found" }, 404);
  }

  await roomRepository.remove(room);

  sendOkResponse(res, { message: "Room deleted successfully" });
});

export const updateRoom = asyncHandler(async (req: Request, res: Response) => {
  const roomId = parseInt(req.params.roomId, 10);
  if (isNaN(roomId)) {
    return sendErrorResponse(res, { message: "Invalid room ID" }, 400);
  }

  const { room: roomToUpdate } = req.body as { room: Room };

  const { name, location, description, imageUrl, shortName } = roomToUpdate;

  const roomRepository = AppDataSource.getRepository(Room);
  const room = await roomRepository.findOneBy({ roomId });

  if (!room) {
    return sendErrorResponse(res, { message: "Room not found" }, 404);
  }

  if (name) room.name = name;
  if (location) room.location = location;
  if (description) room.description = description;
  if (imageUrl) room.imageUrl = imageUrl;
  if (shortName) room.shortName = shortName;

  await roomRepository.save(room);

  sendOkResponse(res, room);
});
