import SensorStabilizer from "../core/SensorStabilizer";
import { MachineStatus } from "../core/types";
import { Reading } from "../entities/v2/events/events.controller";
import { AbstractMachine } from "./Machine";

export class Dryer extends AbstractMachine {
  protected stabilizer: SensorStabilizer;

  constructor() {
    super();
    this.stabilizer = new SensorStabilizer();
  }

  getStatus(readings: Reading[]): MachineStatus {
    // expect readings to be a size=2 array
    // if not size 2, return UNKNOWN
    if (readings.length !== 2) {
      return MachineStatus.UNKNOWN;
    }

    const reading1 = readings[0];
    const reading2 = readings[1];

    // if reading 1 > threshold, machine is IN_USE
    // if reading 2 > threshold, machine is FINISHING
    // if both readings are below threshold, machine is AVAILABLE
    if (reading1.value > reading1.threshold) {
      return MachineStatus.IN_USE;
    }
    if (reading2.value > reading2.threshold) {
      return MachineStatus.FINISHING;
    }
    return MachineStatus.AVAILABLE;
  }
}
