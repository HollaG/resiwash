import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { Area } from "../../../models/Area";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import asyncHandler from "express-async-handler";

interface GetAreaRequest {
  areaIds?: string[];
}
export const getAreas = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetAreaRequest>,
    res: Response
  ) => {
    const { areaIds = [] } = req.query;
    const areaRepository = AppDataSource.getRepository(Area);
    let areas = areaRepository.createQueryBuilder("area");

    if (areaIds.length > 0) {
      areas = areas.where("area.id IN (:...areaIds)", { areaIds });
    }
    areas = areas.orderBy("area.name", "ASC");
    const areaList = await areas.getMany();

    sendOkResponse(res, areaList);
  }
);

export const createArea = async (req: Request, res: Response) => {
  // expected fields: name
  // optional fields: location, description, imageUrl, shortName

  // todo: authentication and authorization

  console.log("createArea", req.body);

  const { name, location, description, imageUrl, shortName } = req.body;

  if (!name) {
    return sendErrorResponse(res, { message: "Name is required" }, 400);
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
  const areaId = parseInt(req.params.id, 10);
  if (isNaN(areaId)) {
    return sendErrorResponse(res, { message: "Invalid area ID" }, 400);
  }

  const areaRepository = AppDataSource.getRepository(Area);
  const area = await areaRepository.findOneBy({ areaId });

  if (!area) {
    return sendErrorResponse(res, { message: "Area not found" }, 404);
  }

  await areaRepository.remove(area);

  sendOkResponse(res, { message: "Area deleted successfully" });
});
