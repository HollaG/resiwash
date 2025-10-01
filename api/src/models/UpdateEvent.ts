// UpdateEvents should be `immutable`.

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from "typeorm";
import { Machine } from "./Machine";
import { MachineStatus } from "../core/types";
import { Reading } from "../entities/v2/events/events.controller";

@Entity()
export class UpdateEvent {
  @PrimaryGeneratedColumn()
  eventId: number;

  @CreateDateColumn()
  timestamp: Date;

  @Column({ type: "enum", enum: MachineStatus, nullable: true })
  status: MachineStatus;

  // deprecated
  // use status instead
  @Column({ nullable: true })
  statusCode: number;

  @Column({ type: "json", nullable: true })
  readings: Reading[];

  @ManyToOne(() => Machine, (machine) => machine.events)
  @JoinColumn({ name: "machineId" })
  machine: Machine;
}
