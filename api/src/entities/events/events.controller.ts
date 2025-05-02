import { Request, Response } from "express";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import asyncHandler from "express-async-handler";
import { UpdateEvent } from "../../models/UpdateEvent";

export const getEvents = asyncHandler(async (req: Request, res: Response) => {
  const eventRepository = AppDataSource.getRepository(UpdateEvent);

  // last 100 events
  const events = await eventRepository.find({
    order: {
      timestamp: "DESC",
    },
    take: 100,
  });

  sendOkResponse(res, events);
});

export const createEvent = asyncHandler(async (req: Request, res: Response) => {
  // expected fields: statusCode, machineId
  // optional fields: status

  // todo: authentication via API key

  console.log("createEvent", req.body);

  const { status, machineId, statusCode } = req.body;

  if (statusCode === undefined) {
    return sendErrorResponse(res, "Status code is required", 400);
  }

  if (!machineId || Number(machineId) <= 0) {
    return sendErrorResponse(res, "Machine ID is required", 400);
  }

  const eventRepository = AppDataSource.getRepository(UpdateEvent);

  const event = new UpdateEvent();
  event.statusCode = statusCode;
  event.machine = { machineId: Number(machineId) } as any; // type assertion to satisfy TypeScript

  await eventRepository.save(event);

  sendOkResponse(res, event);
});

export const createMultipleEvents = asyncHandler(
  async (req: Request, res: Response) => {
    // expected fields: data: { statusCode, machineId, status? }[]
    // optional fields: status

    console.log("createMultipleEvents", req.body);

    const { data }: { data: { statusCode: number; machineId: number; status?: string }[] } = req.body;

    if (!data || !Array.isArray(data)) {
      return sendErrorResponse(res, "Data is required", 400);
    }

    if (data.length === 0) {
      return sendErrorResponse(res, "Data is empty", 400);
    }

    const eventRepository = AppDataSource.getRepository(UpdateEvent);

    const events = data.map((item) => {
      if (item.statusCode === undefined) {
        throw new Error("Status code is required");
      }

      if (!item.machineId || Number(item.machineId) <= 0) {
        throw new Error("Machine ID is required");
      }

      const event = new UpdateEvent();
      event.statusCode = item.statusCode;
      event.machine = { machineId: Number(item.machineId) } as any; // type assertion to satisfy TypeScript

      return event;
    });

    await eventRepository.save(events);

    sendOkResponse(res, events);

  }
);
