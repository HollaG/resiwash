import { Request, Response } from "express";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import asyncHandler from "express-async-handler";
import { UpdateEvent } from "../../models/UpdateEvent";
import { Machine } from "../../models/Machine";
import SensorStabilizer from "../../core/SensorStabilizer";
import { RawEvent } from "../../models/RawEvent";
import { Sensor } from "../../models/Sensor";
import { SensorToMachine } from "../../models/SensorToMachine";
import { In } from "typeorm";
import { MachineStatus, STATUS_CODE_MAP } from "../../core/types";

const debounceMachineMap: {
  [machineId: number]: SensorStabilizer;
} = {};

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
  // to implement!
  // // expected fields: statusCode, machineId
  // // optional fields: status
  // // todo: authentication via API key
  // console.log("createEvent", req.body);
  // const { status, machineId, statusCode } = req.body;
  // try {
  //   const event = await saveEvent({ status, machineId, statusCode });
  //   sendOkResponse(res, event);
  // } catch (error) {
  //   console.error("Error saving event:", error);
  //   return sendErrorResponse(res, error.message, 500);
  // }
  // // if (statusCode === undefined) {
  // //   return sendErrorResponse(res, "Status code is required", 400);
  // // }
  // // if (!machineId || Number(machineId) <= 0) {
  // //   return sendErrorResponse(res, "Machine ID is required", 400);
  // // }
  // // const eventRepository = AppDataSource.getRepository(UpdateEvent);
  // // // get the latest event for the machine
  // // const latestEvent = await eventRepository.findOne({
  // //   where: {
  // //     machine: { machineId: Number(machineId) },
  // //   },
  // //   order: {
  // //     timestamp: "DESC",
  // //   },
  // // });
  // // // if the latest event is NOT the same as the new event, OR there is no latest event, create a new event
  // // if (!latestEvent || latestEvent.statusCode !== statusCode) {
  // //   const event = new UpdateEvent();
  // //   event.statusCode = statusCode;
  // //   event.machine = { machineId: Number(machineId) } as any; // type assertion to satisfy TypeScript
  // //   await eventRepository.save(event);
  // //   sendOkResponse(res, event);
  // // } else {
  // //   // update the machine's lastUpdated timestamp
  // //   const machine = await AppDataSource.getRepository(Machine).findOne({
  // //     where: { machineId: Number(machineId) },
  // //   });
  // //   if (!machine) {
  // //     return sendErrorResponse(res, "Machine not found", 404);
  // //   }
  // //   machine.lastUpdated = new Date(); // update the lastUpdated timestamp
  // //   await AppDataSource.getRepository(Machine).save(machine);
  // //   return sendOkResponse(res, latestEvent); // return the latest event
  // // }
});

type EspEvent = {
  macAddress: string; // mac address of the machine

  localId: number; // localId
  state: number; // integer
  source: string; // source
  strategy: number; // strategy, unused for now. Can be AND, OR, etc
  readings: Reading[];
};
type Reading = {
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
    console.log("createMultipleEvents", req.body);

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

    console.log("createMultipleEvents debug machineIds", machineIds);

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
          const status = STATUS_CODE_MAP[statusCode] as MachineStatus;
          rawEvent.status = status;

          rawEvent.readings = readings;
          rawEvent.machine = { machineId: machine.machineId } as any; // type assertion to satisfy TypeScript
          rawEvents.push(rawEvent);

          // --------- for actual events ---------
          if (!debounceMachineMap[machine.machineId]) {
            debounceMachineMap[machine.machineId] = new SensorStabilizer();
          }

          const actualEvent = new UpdateEvent();

          const debouncedStatus =
            debounceMachineMap[machine.machineId].update(status);
          actualEvent.status = debouncedStatus;

          // find the latest event for this machine
          const latestEvent = latestEvents.find(
            (event) => event.machine.machineId === machine.machineId
          );

          if (!latestEvent || latestEvent.status !== status) {
            const event = new UpdateEvent();

            event.status = status;
            event.machine = { machineId: Number(machine.machineId) } as any; // type assertion to satisfy TypeScript

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

    console.log("createMultipleEvents debug actualEvents", actualEvents);
    console.log(
      "createMultipleEvents debug machineIdsToUpdate",
      machineIdsToUpdate
    );
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

    //   const event = new UpdateEvent();
    //   event.statusCode = item.statusCode;
    //   event.machine = { machineId: Number(item.machineId) } as any; // type assertion to satisfy TypeScript

    //   return event;
    // });

    // await eventRepository.save(events);
  }
);

/**
 * Create a single event from manual entry.
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
const saveEvent = async ({
  machineId,
  statusCode: rawStatusCode,
}: {
  machineId: number;
  statusCode: number;
}) => {
  if (rawStatusCode === undefined) {
    throw new Error("Status code is required");
  }

  const status = STATUS_CODE_MAP[rawStatusCode] as MachineStatus;

  if (!machineId || Number(machineId) <= 0) {
    throw new Error("Machine ID is required");
  }

  const eventRepository = AppDataSource.getRepository(UpdateEvent);

  // get the latest event for the machine
  const latestEvent = await eventRepository.findOne({
    where: {
      machine: { machineId: Number(machineId) },
    },
    order: {
      timestamp: "DESC",
    },
  });

  const machine = await AppDataSource.getRepository(Machine).findOne({
    where: { machineId: Number(machineId) },
  });

  if (!machine) {
    throw new Error("Machine not found");
  }
  machine.lastUpdated = new Date(); // update the lastUpdated timestamp

  await AppDataSource.getRepository(Machine).save(machine);

  // always save to raw events
  const rawEvent = new RawEvent();
  rawEvent.statusCode = rawStatusCode;
  rawEvent.machine = { machineId: Number(machineId) } as any; // type assertion to satisfy TypeScript
  const rawEventRepository = AppDataSource.getRepository(RawEvent);
  await rawEventRepository.save(rawEvent);

  if (!debounceMachineMap[machineId]) {
    debounceMachineMap[machineId] = new SensorStabilizer();
  }

  let debouncedStatus = debounceMachineMap[machineId].update(status);

  // if the latest event is NOT the same as the new event, OR there is no latest event, create a new event
  if (!latestEvent || latestEvent.status !== debouncedStatus) {
    const event = new UpdateEvent();
    event.status = debouncedStatus;
    event.machine = { machineId: Number(machineId) } as any; // type assertion to satisfy TypeScript

    await eventRepository.save(event);

    return event;
  } else {
    return latestEvent; // TODO: do we need to return the latest event?
  }
};
