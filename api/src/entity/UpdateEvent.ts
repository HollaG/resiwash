import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne } from "typeorm";
import { Machine } from "./Machine";

@Entity()
export class UpdateEvent {
  @PrimaryGeneratedColumn()
  eventId: number;

  @Column()
  timestamp: Date;

  @Column()
  status: string;

  @ManyToOne(() => Machine, (machine) => machine.events)
  machine: Machine;

}
