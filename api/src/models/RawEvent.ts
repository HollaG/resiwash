// UpdateEvents should be `immutable`.
type Reading = {
  value: number;
  threshold: number;
};

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

@Entity()
export class RawEvent {
  @PrimaryGeneratedColumn()
  eventId: number;

  @CreateDateColumn()
  timestamp: Date;

  @Column()
  statusCode: number;

  @Column({ type: "json" })
  readings: Reading[];

  @ManyToOne(() => Machine, (machine) => machine.events)
  @JoinColumn({ name: "machineId" })
  machine: Machine;
}
