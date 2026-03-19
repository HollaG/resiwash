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
import { In, MoreThanOrEqual } from "typeorm";
import {
  GetQueryBoolean,
  isAvailableLike,
  MachineStatus,
  MachineType,
  STATUS_CODE_MAP,
} from "../../../core/types";
import { AbstractMachine } from "../../../classes/Machine";
import { Dryer } from "../../../classes/Dryer";
import { Washer } from "../../../classes/Washer";
import { sendMachineGroupStatusChangedNotification } from "../../../utils/firebase-messaging";
import {
  getClaimants,
  sendNotificationToClaimants,
  unclaimMachine,
} from "../../../utils/notifications";

// saves IN-MEMORY which machines have been sending data
// TODO: migrate to Redis in future
const activeMachines: { [machineId: number]: AbstractMachine } = {};

interface GetEventsRequest {
  machineIds?: string[];
  raw?: GetQueryBoolean;
  // PageReq: PageReq  // future pagination
}

export const getEvents = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetEventsRequest>,
    res: Response,
  ) => {
    req.log.info("getEvents", req.query);

    const { machineIds = [], raw = GetQueryBoolean.FALSE } = req.query;

    // Calculate date one week ago
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    if (GetQueryBoolean.parse(raw)) {
      const rawEventRepository = AppDataSource.getRepository(RawEvent);
      let events: RawEvent[] = [];
      if (!machineIds || machineIds.length === 0) {
        // last week
        events = await rawEventRepository.find({
          where: {
            timestamp: MoreThanOrEqual(oneWeekAgo),
          },
          order: {
            timestamp: "ASC",
          },
        });
      } else {
        events = await rawEventRepository.find({
          where: {
            machine: { machineId: In(machineIds.map(Number)) },
            timestamp: MoreThanOrEqual(oneWeekAgo),
          },
          order: {
            timestamp: "ASC",
          },
        });
      }
      sendOkResponse(res, events);
    } else {
      const eventRepository = AppDataSource.getRepository(UpdateEvent);
      let events: UpdateEvent[] = [];
      if (!machineIds || machineIds.length === 0) {
        // last week
        events = await eventRepository.find({
          where: {
            timestamp: MoreThanOrEqual(oneWeekAgo),
          },
          order: {
            timestamp: "ASC",
          },
        });
      } else {
        events = await eventRepository.find({
          where: {
            machine: { machineId: In(machineIds.map(Number)) },
            timestamp: MoreThanOrEqual(oneWeekAgo),
          },
          order: {
            timestamp: "ASC",
          },
        });
      }
      sendOkResponse(res, events);
    }
  },
);

/**
 * Get the events formatted in uplot data format
 * x-values: timestamps in ms
 * y-values:
 *   series (n): reading[0].threshold
 *   series (n+1): reading[0].value
 *
 * expected format:
 *   [
 *     [timestamp1, timestamp2, ...],  // x values
 *     [reading1[0].threshold, reading2[0].threshold, ...], // y values for series 1
 *     [reading1[0].value, reading2[0].value, ...], // y values for series 2
 *     [reading1[1].threshold, reading2[1].threshold, ...], // y values for series 3 (if exists)
 *     [reading1[1].value, reading2[1].value, ...], // y values for series 4 (if exists)
 *   ]
 *
 */

interface GetEventsFormattedRequest {
  machineIds?: string[];
  raw?: GetQueryBoolean;
}
interface GetEventsFormattedResponse {
  points: number[][];
  series: string[];
}
export const getEventsFormatted = asyncHandler(
  async (
    req: Request<unknown, unknown, unknown, GetEventsFormattedRequest>,
    res: Response<GetEventsFormattedResponse, unknown>,
  ) => {
    req.log.info("getEventsFormatted", req.query);
    try {
      const { machineIds = [], raw = GetQueryBoolean.FALSE } =
        req.query as GetEventsFormattedRequest;

      if (!machineIds || machineIds.length === 0) {
        return sendErrorResponse(res, "Machine IDs are required", 400);
      }

      // Calculate date one week ago
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      // convert events to uplot format
      const data: number[][] = [];
      if (GetQueryBoolean.parse(raw)) {
        const rawEventRepository = AppDataSource.getRepository(RawEvent);
        let events: RawEvent[] = [];
        if (!machineIds || machineIds.length === 0) {
          // last week
          events = await rawEventRepository.find({
            where: {
              timestamp: MoreThanOrEqual(oneWeekAgo),
            },
            order: {
              timestamp: "ASC",
            },
          });
        } else {
          events = await rawEventRepository.find({
            where: {
              machine: { machineId: In(machineIds.map(Number)) },
              timestamp: MoreThanOrEqual(oneWeekAgo),
            },
            order: {
              timestamp: "ASC",
            },
          });
        }

        // convert to uplot format
        // x values: timestamps in ms
        // y values: series (n): reading[0].threshold, series (n+1): reading[0].value
        const xValues: number[] = [];
        const yValuesThreshold: number[] = [];
        const yValuesValue: number[] = [];
        const yValuesThreshold2: number[] = [];
        const yValuesValue2: number[] = [];

        events.forEach((event) => {
          xValues.push(Math.floor(event.timestamp.getTime() / 1000));
          yValuesThreshold.push(event.readings[0].threshold);
          yValuesValue.push(event.readings[0].value);
          if (event.readings[1]) {
            yValuesThreshold2.push(event.readings[1].threshold);
            yValuesValue2.push(event.readings[1].value);
          }
        });

        data.push(xValues, yValuesThreshold, yValuesValue);
        if (yValuesThreshold2.length > 0 && yValuesValue2.length > 0) {
          data.push(yValuesThreshold2, yValuesValue2);
        }
      } else {
        const eventRepository = AppDataSource.getRepository(UpdateEvent);
        let events: UpdateEvent[] = [];
        if (!machineIds || machineIds.length === 0) {
          // last week
          events = await eventRepository.find({
            where: {
              timestamp: MoreThanOrEqual(oneWeekAgo),
            },
            order: {
              timestamp: "ASC",
            },
          });
        } else {
          events = await eventRepository.find({
            where: {
              machine: { machineId: In(machineIds.map(Number)) },
              timestamp: MoreThanOrEqual(oneWeekAgo),
            },
            order: {
              timestamp: "ASC",
            },
          });
        }

        // convert to uplot format
        // x values: timestamps in ms
        // y values: series (n): reading[0].threshold, series (n+1): reading[0].value
        const xValues: number[] = [];
        const yValuesThreshold: number[] = [];
        const yValuesValue: number[] = [];
        const yValuesThreshold2: number[] = [];
        const yValuesValue2: number[] = [];

        events.forEach((event) => {
          xValues.push(Math.floor(event.timestamp.getTime() / 1000));
          yValuesThreshold.push(event.readings[0].threshold);
          yValuesValue.push(event.readings[0].value);
          if (event.readings[1]) {
            yValuesThreshold2.push(event.readings[1].threshold);
            yValuesValue2.push(event.readings[1].value);
          }
        });

        data.push(xValues, yValuesThreshold, yValuesValue);
        if (yValuesThreshold2.length > 0 && yValuesValue2.length > 0) {
          data.push(yValuesThreshold2, yValuesValue2);
        }
      }

      const response: GetEventsFormattedResponse = {
        points: data,
        // todo: this may not always be the case in the future if we ever have sensors with more than 2 / less than 1
        series: ["Threshold 1", "Value 1", "Threshold 2", "Value 2"],
      };
      sendOkResponse(res, response);
    } catch (err) {
      console.error("Error in getEventsFormatted", err);
      return sendErrorResponse(res, "Internal server error", 500);
    }
  },
);

export const createEvent = asyncHandler(async (req: Request, res: Response) => {
  // to implement!
  // // expected fields: statusCode, machineId
  // // optional fields: status
  // // todo: authentication via API key
  // req.log.info("createEvent", req.body);
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
    // if (process.env.DEBUG_SENSOR)
    //   req.log.info("createMultipleEvents", req.body);

    const data = req.body.data as EspEvent[];
    const macAddress = req.body.macAddress as string;

    if (!macAddress) {
      return sendErrorResponse(res, "MAC address is required", 400);
    }

    console.log(
      `received createMultipleEvents request from sensor ${macAddress}`,
    );

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

    // req.log.info("createMultipleEvents debug sensor", sensor);

    // get all SensorToMachine links for the sensor
    const sensorToMachineRepository =
      AppDataSource.getRepository(SensorToMachine);
    const sensorLinks = await sensorToMachineRepository.find({
      where: { sensorId: sensor.sensorId, machine: { isManualEntry: false } },
      relations: ["machine"],
    });

    if (sensorLinks.length === 0) {
      return sendErrorResponse(
        res,
        "No machine links found for the sensor",
        404,
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
      .andWhere("machine.isManualEntry = false")

      .orderBy("event.machineId", "ASC")
      .addOrderBy("event.timestamp", "DESC")
      .getMany();

    const rawEvents: RawEvent[] = [];
    const actualEvents: UpdateEvent[] = [];

    for (const espEvent of data) {
      // convert EspEvent to UpdateEvent
      const machine = sensorLinks.find((link) => {
        return (
          link.source === espEvent.source && link.localId === espEvent.localId
        );
      });

      if (!machine) {
        console.log(
          "No machine link found for source:",
          espEvent.source,
          "and localId:",
          espEvent.localId,
        );
        // return sendErrorResponse(res, `No machine link found for source: ${espEvent.source} and localId: ${espEvent.localId}`, 404);
      } else {
        const rawEvent = new RawEvent();
        const { state: statusCode, readings } = espEvent;

        if (!STATUS_CODE_MAP[statusCode]) {
          // continue;
        } else {
          const rawStatus = STATUS_CODE_MAP[statusCode] as MachineStatus;
          rawEvent.status = rawStatus; // note that the raw status will SOLELY be based on the ESP's data, which is 1 if any of the LDRs are above threshold
          // todo: we can change this such that it is the processed status instead, maybe?

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
              `No active machine found for machineId: ${machine.machineId}, using raw status`,
            );
          }

          // --------- for actual events ---------
          // if (!debounceMachineMap[machine.machineId]) {
          //   debounceMachineMap[machine.machineId] = new SensorStabilizer();
          // }

          const actualEvent = new UpdateEvent();

          // const debouncedStatus =
          //   debounceMachineMap[machine.machineId].update(rawStatus);

          /**
           * Important notice: In order to support extra states e.g. Finished state
           * which do NOT directly map to sensor readings,
           * we need to compute the effective status BEFORE the state-change check.
           *
           * Here are the conditions checked thus far:
           * 1. [is the machine claimed?]
           *   If machine is claimed and status transits to AVAILABLE,
           *     then we should set the status to FINISHED instead, since the machine has finished its cycle and is waiting for clothes to be cleared.
           *
           * A few cases can occur:
           * 1. user claims machine while machine sensor still reads available
           *   No actual event is generated as status = activeMachine.update(readings) will still read AVAILABLE, `status` is still AVAILABLE. Thus, the `if` statement
           *   below will not even run.
           * 2. machine is in use, user claims machine, machine finishes cycle and transits to AVAILABLE
           *   The latestEvent.status will be FINISHING (or IN_USE), while the `effectiveStatus` will be FINISHED. This passes the `if` block.
           *   On the NEXT sensor tick, latestEvent.status = FINISHED and effectiveStatus = FINISHED → NO new event. Loop stops.
           *   Once the user unclaims, the `unclaim` method inserts a dummy AVAILABLE event, so latestEvent.status becomes AVAILABLE.
           *     This is good for us as it is the same for both manual and automatic machine methods.
           *
           * NOTE: effectiveStatus must be used for BOTH the state-change guard and actualEvent.status.
           * Using the raw `status` for the guard but saving FINISHED leads to an infinite flood:
           *   latestEvent.status=FINISHED vs status=AVAILABLE → always different → new FINISHED event every 10s.
           */

          // This code presents a problem, because we can't tell when someone has 
          // either a) claimed a free machine (waiting to start)
          // or b) machine finished.
          // If the detected status is now "AVAILABLE" AND there is a claimId AND the curremt machine status is "AVAILABLE", then we know that this machine was claimed from available state.
          //   Nothing should be done in this state as we should NOT transition to Finished
          // If the detected status is "AVAILABLE" AND there is a claimId BUT the current machine status is NOT "AVAILABLE", then we know that this sensor has detected the machine has just finished.
          //   We should transition to FINISHED in this case.
          // If there is no claimId, no change.
          let effectiveStatus = status;
          if (machine.machine.claimId) {
            if (status === MachineStatus.AVAILABLE && machine.machine.currentStatus === MachineStatus.AVAILABLE) {
              effectiveStatus = status; // make sure no change
            } else if (status === MachineStatus.AVAILABLE && machine.machine.currentStatus !== MachineStatus.AVAILABLE) {
              effectiveStatus = MachineStatus.FINISHED; // machine has just finished, transition to FINISHED
            }
          }

          actualEvent.status = effectiveStatus;
          actualEvent.readings = readings;
          actualEvent.machine = { machineId: Number(machine.machineId) } as any; // type assertion to satisfy TypeScript

          // find the latest event for this machine
          const latestEvent = latestEvents.find(
            (event) => event.machine.machineId === machine.machineId,
          );

          if (!latestEvent || latestEvent.status !== effectiveStatus) {
            // if there is a state change detected

            if (machine.machine.currentStatus === MachineStatus.FINISHED && (effectiveStatus === MachineStatus.IN_USE || effectiveStatus === MachineStatus.FINISHING)) {
              // edge case:
              // machine FINISHED (aka CLAIMED && BECAME AVAILABLE)
              // sensor is trying to go into in_use_like state
              // unclaim the machine
              machine.machine.claimId = null; // remove the claim association but leave it in the claim history
              machine.machine.claim = null;

              // save

              await machineRepository.update(
                { machineId: machine.machineId },
                { claimId: null, claim: null }
              );
              // machineRepository.save(machine.machine);

            }
            actualEvents.push(actualEvent);
          } else {
            // NO STATE CHANGE
            // machine's lastUpdated timestamp comes from latest event
          }
        }
      }
    }

    const savedRawEvents = await rawEventRepository.save(rawEvents);

    // ------- raw events always get saved -------
    // for all raw events, update the machine's lastUpdated timestamp
    const machineIdsToUpdate = rawEvents.map(
      (event) => event.machine.machineId,
    );

    // machinesToUpdate contains all machines that were sent an event
    const machinesToUpdate = await machineRepository.find({
      where: { machineId: In(machineIdsToUpdate), isManualEntry: false },
      // join with the room and area data as well
      relations: ["room", "room.area", "claim"],
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

    const machinesToSave: Machine[] = [];
    actualEvents.forEach((event) => {
      const machine = machinesToUpdate.find(
        (m) => m.machineId === event.machine.machineId,
      );
      if (machine) {
        const now = new Date();
        machine.lastChangeTime = now; // update the lastChangeTime timestamp
        machine.previousStatus = machine.currentStatus; // copy the currentStatus to previousStatus
        machine.currentStatus = event.status; // set the currentStatus to the new status
        machine.previousStatusActiveTime = machine.lastChangeTime
          ? Math.floor(
            (machine.lastChangeTime.getTime() -
              machine.lastUpdated!.getTime()) /
            1000,
          )
          : 0; // calculate how long the machine was in the previous status in seconds

        if (isAvailableLike(machine.currentStatus)) {
          machine.lastAvailableTime = now; // the machine is now available, so update lastAvailableTime to now. in a sense, this is more of "firstAvailableTime" but we'll run with it
          // but, keep the claim Id
        } else if (isAvailableLike(machine.previousStatus)) {
          machine.lastAvailableTime = now; // the machine has now become not available, so NOW is the last available time
        }

        machinesToSave.push(machine);
      }
    });
    await machineRepository.save(machinesToSave);

    for (const machine of machinesToSave) {
      // asynchronously send notification
      // note: we do not care if it succeeds or fails
      sendMachineGroupStatusChangedNotification({
        machineId: machine.machineId,
        machine,
      });

      // send notification to claimant if applicable
      sendNotificationToClaimants(machine.machineId).catch((e) => { }); // do nothing
    }

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
    //   req.log.debug("error: ", errors)
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
  },
);
