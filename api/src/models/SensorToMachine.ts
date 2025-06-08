import { Entity, PrimaryColumn, Column, ManyToOne, JoinColumn, OneToOne } from "typeorm";
import { Machine } from "./Machine";
import { Sensor } from "./Sensor";

@Entity()
export class SensorToMachine {
  @PrimaryColumn()
  sensorId: number;

  @PrimaryColumn({ type: "varchar", length: 64 })
  source: string;

  @PrimaryColumn()
  localId: number;

  @Column({ unique: true })
  machineId: number;

  @ManyToOne(() => Sensor)
  @JoinColumn({ name: "sensorId" })
  sensor: Sensor;

  @OneToOne(() => Machine)
  @JoinColumn({ name: "machineId" })
  machine: Machine;
}