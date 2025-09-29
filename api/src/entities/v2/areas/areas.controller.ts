import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { Area } from "../../../models/Area";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import asyncHandler from "express-async-handler";

interface GetAreasRequest {
  areaIds?: string[];
}

export const getAreas = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetAreasRequest>,
    res: Response
  ) => {
    const { areaIds = [] } = req.query;

    const areaRepository = AppDataSource.getRepository(Area);

    let areas = areaRepository.createQueryBuilder("area");
    if (areaIds.length > 0) {
      areas = areas.where("area.areaId IN (:...areaIds)", {
        areaIds: areaIds.map(Number),
      });
    }
    areas = areas.orderBy("area.name", "ASC");
    areas = areas.addOrderBy("area.areaId", "ASC");

    const areasList = await areas.getMany();

    sendOkResponse(res, areasList);
  }
);

export const getArea = asyncHandler(async (req: Request, res: Response) => {
  // return empty for now, not implemented

  sendOkResponse(res, {});
});

export const createArea = async (req: Request, res: Response) => {
  // expected fields: name
  // optional fields: location, description, imageUrl, shortName

  // todo: authentication and authorization

  console.log("createArea", req.body);

  const { area: areaToCreate } = req.body as { area: Area };

  const { name, location, description, imageUrl, shortName } = areaToCreate;

  if (!name) {
    return sendErrorResponse(res, "Name is required", 400);
  }

  const area = new Area();
  area.name = name;
  area.location = location || null;
  area.description = description || null;
  area.imageUrl = imageUrl || null;
  area.shortName = shortName || null;

  const areaRepository = AppDataSource.getRepository(Area);
  await areaRepository.save(area);

  sendOkResponse(res, area);
};

export const deleteArea = asyncHandler(async (req: Request, res: Response) => {
  const areaId = parseInt(req.params.roomId, 10);
  if (isNaN(areaId)) {
    return sendErrorResponse(res, "Invalid area ID", 400);
  }

  const areaRepository = AppDataSource.getRepository(Area);
  const area = await areaRepository.findOneBy({ areaId });

  if (!area) {
    return sendErrorResponse(res, "Area not found", 404);
  }

  await areaRepository.remove(area);

  sendOkResponse(res, { message: "Area deleted successfully" });
});

export const updateArea = asyncHandler(async (req: Request, res: Response) => {
  const areaId = parseInt(req.params.roomId, 10);
  if (isNaN(areaId)) {
    return sendErrorResponse(res, "Invalid area ID", 400);
  }

  const { area: areaToUpdate } = req.body as { area: Area };

  const { name, location, description, imageUrl, shortName } = areaToUpdate;

  const areaRepository = AppDataSource.getRepository(Area);
  let area = await areaRepository.findOneBy({ areaId });

  if (!area) {
    return sendErrorResponse(res, "Area not found", 404);
  }

  area.name = name || area.name;
  area.location = location || area.location;
  area.description = description || area.description;
  area.imageUrl = imageUrl || area.imageUrl;
  area.shortName = shortName || area.shortName;

  await areaRepository.save(area);

  sendOkResponse(res, area);
});
