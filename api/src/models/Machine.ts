import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";
import { Room } from "./Room";
import { UpdateEvent } from "./UpdateEvent";
import { MachineType } from "../core/types";
import { RawEvent } from "./RawEvent";

@Entity()
export class Machine {
  @PrimaryGeneratedColumn()
  machineId: number;

  @Column()
  name: string;

  @Column()
  label: string;

  @Column({
    type: "enum",
    enum: MachineType
  })
  type: MachineType; // Washer, Dryer, etc.

  @Column({ nullable: true })
  imageUrl: string; // e.g., "https://example.com/image.jpg"

  @ManyToOne(() => Room, (room) => room.machines)
  @JoinColumn({ name: "roomId" })
  room: Room;

  @OneToMany(() => UpdateEvent, (evt) => evt.machine)
  events: UpdateEvent[];

  @OneToMany(() => RawEvent, (evt) => evt.machine)
  rawEvents: RawEvent[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  lastUpdated: Date; // Last time that there was an update from the sensor
}
