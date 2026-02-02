import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import { Sensor } from "../../../models/Sensor";
import { Room } from "../../../models/Room";
import { Machine } from "../../../models/Machine";
import { Request, Response } from "express";
import { SensorToMachine } from "../../../models/SensorToMachine";

export const getSensors = asyncHandler(async (req: Request, res: Response) => {
  // Fetch sensors from the database
  const sensorRepository = AppDataSource.getRepository(Sensor);
  const sensors = await sensorRepository.find({
    relations: ["room"], // Include the room relation if needed
  });

  console.log("getSensors", sensors);

  sendOkResponse(res, sensors);
});

export const getSensor = asyncHandler(async (req: Request, res: Response) => {
  const sensorId = parseInt(req.params.id, 10);
  if (isNaN(sensorId)) {
    return sendErrorResponse(res, "Invalid sensor ID", 400);
  }
  const sensorRepository = AppDataSource.getRepository(Sensor);
  const sensor = await sensorRepository.findOneBy({ sensorId });
  if (!sensor) {
    return sendErrorResponse(res, "Sensor not found", 404);
  }
  sendOkResponse(res, sensor);
});

// for hardware only
export const registerSensor = asyncHandler(
  async (req: Request, res: Response) => {
    console.log("registerSensor", req.body);
    const { macAddress } = req.body;

    if (!macAddress) {
      res.status(400).json({ error: "macAddress is required" });
      return;
    }

    const sensor = new Sensor();
    sensor.macAddress = macAddress;

    const sensorRepository = AppDataSource.getRepository(Sensor);

    // Check if a sensor with the same macAddress already exists
    const existingSensor = await sensorRepository.findOneBy({ macAddress });
    if (existingSensor) {
      res
        .status(400)
        .json({ error: "Sensor with this macAddress already exists" });
      return;
    }

    await sensorRepository.save(sensor);

    sendOkResponse(res, sensor);
  }
);

// for setting API endpoint and API key
export const setSensorApiKey = asyncHandler(
  async (req: Request, res: Response) => {
    console.log("setSensorApiKey", req.body);

    const { apiKey, roomId } = req.body;

    if (!apiKey && !roomId) {
      res.status(400).json({ error: "apiKey or roomId is required" });
      return;
    }

    if (Number.isNaN(Number(req.params.id))) {
      res.status(400).json({ error: "Invalid sensor ID" });
      return;
    }

    if (Number.isNaN(Number(roomId)) && roomId !== null) {
      res.status(400).json({ error: "Invalid room ID" });
      return;
    }

    const sensorRepository = AppDataSource.getRepository(Sensor);
    const sensor = await sensorRepository.findOneBy({
      sensorId: Number(req.params.id),
    });

    if (!sensor) {
      res.status(404).json({ error: "Sensor not found" });
      return;
    }

    let room: Room | null = null;
    if (roomId != null) {
      room = await AppDataSource.getRepository(Room).findOneBy({
        roomId: Number(roomId),
      });

      if (!room) {
        res.status(404).json({ error: "Room not found" });
        return;
      }
    }

    if (apiKey != null) sensor.apiKey = apiKey;
    if (room != null) sensor.room = room;

    await sensorRepository.save(sensor);

    sendOkResponse(res, sensor);
  }
);

export const getSensorLinks = asyncHandler(
  async (req: Request, res: Response) => {
    console.log("getSensorLinks", req.params.id);

    if (Number.isNaN(Number(req.params.id))) {
      res.status(400).json({ error: "Invalid sensor ID" });
      return;
    }

    const sensorToMachineRepository =
      AppDataSource.getRepository(SensorToMachine);
    const sensorLinks = await sensorToMachineRepository.find({
      where: { sensorId: Number(req.params.id) },
      relations: ["machine"],
    });

    sendOkResponse(res, sensorLinks);
  }
);

export const setSensorLink = asyncHandler(
  async (req: Request, res: Response) => {
    console.log("setSensorLink", req.body);

    if (Number.isNaN(Number(req.params.id))) {
      res.status(400).json({ error: "Invalid sensor ID" });
      return;
    }

    const sensorToMachineRepository =
      AppDataSource.getRepository(SensorToMachine);

    // Clear existing links for the sensor
    // await sensorToMachineRepository.delete({ sensorId: Number(req.params.id) });

    const { source, localId, machineId } = req.body;
    if (
      source === undefined ||
      localId === undefined ||
      machineId === undefined
    ) {
      res
        .status(400)
        .json({ error: "source, localId, and machineId are required" });
      return;
    }

    // validate sensor existence
    const sensor = await AppDataSource.getRepository(Sensor).findOneBy({
      sensorId: Number(req.params.id),
    });
    if (!sensor) {
      res.status(404).json({ error: "Sensor not found" });
      return;
    }

    // validate machine existence
    const machine = await AppDataSource.getRepository(Machine).findOneBy({
      machineId: Number(machineId),
    });
    if (!machine) {
      res.status(404).json({ error: "Machine not found" });
      return;
    }

    const newLinks = new SensorToMachine();
    newLinks.sensor = sensor;
    newLinks.source = source;
    newLinks.localId = localId;
    newLinks.machine = machine;

    await sensorToMachineRepository.save(newLinks);

    sendOkResponse(res, newLinks);
  }
);

export const deleteSensorLink = asyncHandler(
  async (req: Request, res: Response) => {
    console.log("deleteSensorLink", req.params.id);

    if (Number.isNaN(Number(req.params.id))) {
      res.status(400).json({ error: "Invalid sensor ID" });
      return;
    }

    const sensorToMachineRepository =
      AppDataSource.getRepository(SensorToMachine);

    const sensorId = Number(req.params.id);

    const { source, localId, machineId } = req.body;

    console.log("deleteSensorLink", sensorId, source, localId, machineId);
    if (!source || localId === undefined || machineId === undefined) {
      res
        .status(400)
        .json({ error: "source, localId or machineId are required" });
      return;
    }

    if (Number.isNaN(Number(localId)) || Number.isNaN(Number(machineId))) {
      res.status(400).json({ error: "Invalid localId or machineId" });
      return;
    }

    const sensorLink = await sensorToMachineRepository.findOne({
      where: {
        sensorId: sensorId,
        source: source,
        localId: localId,
        machineId: machineId,
      },
    });

    if (!sensorLink) {
      res.status(404).json({ error: "Sensor link not found" });
      return;
    }

    await sensorToMachineRepository.remove(sensorLink);

    sendOkResponse(res, { message: "Sensor link deleted successfully" });
  }
);
