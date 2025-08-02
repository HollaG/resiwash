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

@Entity()
export class UpdateEvent {
  @PrimaryGeneratedColumn()
  eventId: number;

  @CreateDateColumn()
  timestamp: Date;

  @Column({ type: "enum", enum: MachineStatus })
  status: MachineStatus;

  // deprecated
  // use status instead
  @Column({ nullable: true })
  statusCode: number;

  @Column({ nullable: true })
  reading: number;

  @ManyToOne(() => Machine, (machine) => machine.events)
  @JoinColumn({ name: "machineId" })
  machine: Machine;
}
