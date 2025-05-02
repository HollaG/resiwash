import { Request, Response } from "express";
import { AppDataSource } from "../../data-source";
import { Area } from "../../models/Area";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import asyncHandler from "express-async-handler";

export const getAreas = asyncHandler(async (req: Request, res: Response) => {
  const areaRepository = AppDataSource.getRepository(Area);
  const areas = await areaRepository.find();

  sendOkResponse(res, areas);
});

export const createArea = (async (req: Request, res: Response) => {
  // expected fields: name
  // optional fields: location, description, imageUrl, shortName

  // todo: authentication and authorization

  console.log("createArea", req.body);

  const { name, location, description, imageUrl, shortName } = req.body;

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
});
