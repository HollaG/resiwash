// UpdateEvents should be `immutable`. 

import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne, CreateDateColumn, JoinColumn } from "typeorm";
import { Machine } from "./Machine";

@Entity()
export class RawEvent {
  @PrimaryGeneratedColumn()
  eventId: number;

  @CreateDateColumn()
  timestamp: Date;

  @Column({ nullable: true })
  status: string;

  @Column()
  statusCode: number;

  @ManyToOne(() => Machine, (machine) => machine.events)
  @JoinColumn({ name: "machineId" })
  machine: Machine;

}
