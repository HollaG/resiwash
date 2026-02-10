import {
  Entity,
  PrimaryColumn,
  Column,
  ManyToOne,
  UpdateDateColumn,
  JoinColumn,
} from "typeorm";
import { Machine } from "./Machine";

@Entity()
export class LastPoke {
  @PrimaryColumn()
  machineId: number;

  @ManyToOne(() => Machine, (machine) => machine.machineId)
  @JoinColumn({ name: "machineId" })
  machine: Machine;

  @UpdateDateColumn()
  lastPokeTime: Date;
}
