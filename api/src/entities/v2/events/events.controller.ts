import { Request, Response } from "express";
import { AppDataSource } from "../../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../../core/responses";
import asyncHandler from "express-async-handler";
import { UpdateEvent } from "../../../models/UpdateEvent";
import { Machine } from "../../../models/Machine";
import SensorStabilizer from "../../../core/SensorStabilizer";
import { RawEvent } from "../../../models/RawEvent";
import { Sensor } from "../../../models/Sensor";
import { SensorToMachine } from "../../../models/SensorToMachine";
import { In } from "typeorm";
import {
  MachineStatus,
  MachineType,
  STATUS_CODE_MAP,
} from "../../../core/types";
import { AbstractMachine } from "../../../classes/Machine";
import { Dryer } from "../../../classes/Dryer";
import { Washer } from "../../../classes/Washer";

// const debounceMachineMap: {
//   [machineId: number]: SensorStabilizer;
// } = {};

const activeMachines: { [machineId: number]: AbstractMachine } = {};

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
  return sendErrorResponse(res, { message: "Not implemented" }, 501);
});

type EspEvent = {
  macAddress: string; // mac address of the machine

  localId: number; // localId
  state: number; // integer
  source: string; // source
  strategy: number; // strategy, unused for now. Can be AND, OR, etc
  readings: Reading[];
};
export type Reading = {
  value: number;
  threshold: number;
};

/**
 * Create multiple events from ESP data.
 *
 * Note: the ESP transmits statusCode in order to save bandwidth.
 * We need to convert this to a MachineStatus.
 *
 * This function expects the following request body:
 * {
 *   macAddress: string, // MAC address of the sensor
 *   data: EspEvent[] // array of events
 *  }
 */
export const createMultipleEvents = asyncHandler(
  async (req: Request, res: Response) => {

    const data = req.body.data as EspEvent[];
    const macAddress = req.body.macAddress as string;

    if (!macAddress) {
      return sendErrorResponse(res, "MAC address is required", 400);
    }

    // check to see if valid macAddress exists
    const sensor = await AppDataSource.getRepository(Sensor).findOne({
      where: { macAddress },
    });

    if (!sensor) {
      return sendErrorResponse(res, "Sensor not found", 404);
    }

    if (!data || !Array.isArray(data)) {
      return sendErrorResponse(res, "Data is required", 400);
    }

    // console.log("createMultipleEvents debug sensor", sensor);

    // get all SensorToMachine links for the sensor
    const sensorToMachineRepository =
      AppDataSource.getRepository(SensorToMachine);
    const sensorLinks = await sensorToMachineRepository.find({
      where: { sensorId: sensor.sensorId },
      relations: ["machine"],
    });

    if (sensorLinks.length === 0) {
      return sendErrorResponse(
        res,
        "No machine links found for the sensor",
        404
      );
    }

    const rawEventRepository = AppDataSource.getRepository(RawEvent);
    const actualEventRepository = AppDataSource.getRepository(UpdateEvent);

    const machineIds = sensorLinks.map((link) => link.machineId);
    const machineRepository = AppDataSource.getRepository(Machine);


    const latestEvents = await actualEventRepository
      .createQueryBuilder("event")
      .leftJoinAndSelect("event.machine", "machine")
      .distinctOn(["event.machineId"])
      .where("event.machineId IN (:...machineIds)", { machineIds }) // <-- add this line
      .orderBy("event.machineId", "ASC")
      .addOrderBy("event.timestamp", "DESC")
      .getMany();

    // console.log("createMultipleEvents debug latestEvents", latestEvents);

    const rawEvents: RawEvent[] = [];
    const actualEvents: UpdateEvent[] = [];

    data.forEach((espEvent) => {
      // convert EspEvent to UpdateEvent
      const machine = sensorLinks.find((link) => {
        return (
          link.source === espEvent.source && link.localId === espEvent.localId
        );
      });

      if (!machine) {
        // return sendErrorResponse(res, `No machine link found for source: ${espEvent.source} and localId: ${espEvent.localId}`, 404);
      } else {
        const rawEvent = new RawEvent();
        const { state: statusCode, readings } = espEvent;

        if (!STATUS_CODE_MAP[statusCode]) {
          // continue;
        } else {
          const rawStatus = STATUS_CODE_MAP[statusCode] as MachineStatus;
          rawEvent.status = rawStatus;

          rawEvent.readings = readings;
          rawEvent.machine = machine.machine;
          rawEvents.push(rawEvent);

          // --------- process the actual event using each dryer / washer ---------
          const machineType = machine.machine.type;

          let status = null; // this is the processed status, which may include additional status steps

          switch (machineType) {
            case MachineType.WASHER:
              // if (!activeMachines[machine.machineId]) {
              // activeMachines[machine.machineId] = (
              if (!activeMachines[machine.machineId]) {
                const washer = new Washer();
                activeMachines[machine.machineId] = washer;
              }
            case MachineType.DRYER:
              // valid machine type
              if (!activeMachines[machine.machineId]) {
                const dryer = new Dryer();
                activeMachines[machine.machineId] = dryer;
              }

              break;
          }

          const activeMachine = activeMachines[machine.machineId];
          if (activeMachine) {
            status = activeMachine.update(readings);
          } else {
            status = rawStatus; // fallback to raw status
            console.warn(
              `No active machine found for machineId: ${machine.machineId}, using raw status`
            );
          }

          // --------- for actual events ---------
          // if (!debounceMachineMap[machine.machineId]) {
          //   debounceMachineMap[machine.machineId] = new SensorStabilizer();
          // }

          const actualEvent = new UpdateEvent();

          // const debouncedStatus =
          //   debounceMachineMap[machine.machineId].update(rawStatus);
          actualEvent.status = status;

          // find the latest event for this machine
          const latestEvent = latestEvents.find(
            (event) => event.machine.machineId === machine.machineId
          );

          if (!latestEvent || latestEvent.status !== rawStatus) {
            const event = new UpdateEvent();

            event.status = rawStatus;
            event.machine = machine.machine;

            // await actualEventRepository.save(event);

            // return event;
            actualEvents.push(event);
          } else {
            // NO STATE CHANGE
            // machine's lastUpdated timestamp comes from latest event
          }
        }
      }
    });

    const savedRawEvents = await rawEventRepository.save(rawEvents);

    // ------- raw events always get saved -------
    // for all raw events, update the machine's lastUpdated timestamp
    const machineIdsToUpdate = rawEvents.map(
      (event) => event.machine.machineId
    );

    // machinesToUpdate contains all machines that were sent an event
    const machinesToUpdate = await machineRepository.find({
      where: { machineId: In(machineIdsToUpdate) },
    });

    machinesToUpdate.forEach((machine) => {
      machine.lastUpdated = new Date(); // update the lastUpdated timestamp
    });
    await machineRepository.save(machinesToUpdate);

    const savedActualEvents = await actualEventRepository.save(actualEvents);

    // ------- actual events get saved only if there is a state change -------
    // for all actual events, update the machine's lastChangeTime timestamp,
    // copy the currentStatus to previousStatus,
    // set the currentStatus to the new status
    actualEvents.forEach((event) => {
      const machine = machinesToUpdate.find(
        (m) => m.machineId === event.machine.machineId
      );
      if (machine) {
        machine.lastChangeTime = new Date(); // update the lastChangeTime timestamp
        machine.previousStatus = machine.currentStatus; // copy the currentStatus to previousStatus
        machine.currentStatus = event.status; // set the currentStatus to the new status
      }
    });
    await machineRepository.save(machinesToUpdate);

    sendOkResponse(res, savedRawEvents);

    // const {
    //   data,
    // }: { data: { statusCode: number; machineId: number; status?: string }[] } =
    //   req.body;

    // if (!data || !Array.isArray(data)) {
    //   return sendErrorResponse(res, "Data is required", 400);
    // }

    // if (data.length === 0) {
    //   return sendErrorResponse(res, "Data is empty", 400);
    // }

    // const events = await Promise.allSettled(
    //   // will never reject
    //   data.map((item) => saveEvent(item))
    // );
    // if (events.some((event) => event.status === "rejected")) {
    //   const errors = events
    //     .filter((event) => event.status === "rejected")
    //     .map((event) => (event as PromiseRejectedResult).reason);
    //   console.log("error: ", errors)
    //   return sendErrorResponse(res, errors, 500);
    // }
    // sendOkResponse(
    //   res,
    //   events.map((event) => (event as PromiseFulfilledResult<any>).value)
    // );

    // const eventRepository = AppDataSource.getRepository(UpdateEvent);

    // const events = data.map((item) => {
    //   if (item.statusCode === undefined) {
    //     throw new Error("Status code is required");
    //   }

    //   if (!item.machineId || Number(item.machineId) <= 0) {
    //     throw new Error("Machine ID is required");
    //   }

  }
);
