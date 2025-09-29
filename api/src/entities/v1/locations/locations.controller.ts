import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { Area } from "../../../models/Area";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import asyncHandler from "express-async-handler";

export const getLocations = asyncHandler(
  async (req: Request, res: Response) => {
    const areaRepository = AppDataSource.getRepository(Area);

    // Get all areas with their associated rooms and machine counts using left join
    const areas = await areaRepository
      .createQueryBuilder("area")
      .leftJoinAndSelect("area.rooms", "room")
      .leftJoin("room.machines", "machine")
      .addSelect("COUNT(machine.machineId)", "room_machineCount")
      .groupBy("area.areaId, room.roomId")
      .orderBy("area.name", "ASC")
      .addOrderBy("room.name", "ASC")
      .getRawAndEntities();

    // Transform the result to include machine counts
    const result = areas.entities.map((area) => {
      const areaData = { ...area };
      areaData.rooms = area.rooms.map((room) => {
        const roomRaw = areas.raw.find(
          (raw) => raw.room_roomId === room.roomId
        );
        return {
          ...room,
          machineCount: parseInt(roomRaw?.room_machineCount || "0"),
        };
      });
      return areaData;
    });

    sendOkResponse(res, result);
  }
);
