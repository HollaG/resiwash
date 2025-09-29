import SensorStabilizer from "../core/SensorStabilizer";
import { MachineStatus } from "../core/types";
import { Reading } from "../entities/v2/events/events.controller";

export abstract class AbstractMachine {
  protected stabilizer: SensorStabilizer;
  private currentStatus: MachineStatus = MachineStatus.UNKNOWN;

  constructor() {
    this.stabilizer = new SensorStabilizer();
  }

  abstract getStatus(readings: Reading[]): MachineStatus;

  update(readings: Reading[]): MachineStatus {
    this.currentStatus = this.stabilizer.update(this.getStatus(readings));

    return this.currentStatus;
  }
}
