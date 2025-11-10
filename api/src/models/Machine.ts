import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
} from "typeorm";
import { Room } from "./Room";
import { UpdateEvent } from "./UpdateEvent";
import { MachineStatus, MachineType } from "../core/types";
import { RawEvent } from "./RawEvent";
import { SensorToMachine } from "./SensorToMachine";

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
    enum: MachineType,
  })
  type: MachineType; // Washer, Dryer, etc.

  @Column({ nullable: true })
  imageUrl: string; // e.g., "https://example.com/image.jpg"

  @Column()
  roomId: number; // Foreign key to Room

  @ManyToOne(() => Room, (room) => room.machines)
  @JoinColumn({ name: "roomId" })
  room: Room;

  @OneToMany(() => UpdateEvent, (evt) => evt.machine)
  events: UpdateEvent[];

  @OneToMany(() => RawEvent, (evt) => evt.machine)
  rawEvents: RawEvent[];

  @OneToOne(() => SensorToMachine, (SensorToMachine) => SensorToMachine.machine)
  sensorToMachine: SensorToMachine;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: "timestamp", nullable: true })
  lastUpdated: Date; // Last time that there was an update from the sensor

  // processed fields for easy access
  @Column({ type: "timestamp", nullable: true })
  lastChangeTime: Date; // Last time that the machine changed state (e.g., from in use to available)

  @Column({ nullable: true })
  currentStatus: MachineStatus; // Current status of the machine

  @Column({ nullable: true })
  previousStatus: MachineStatus; // Previous status of the machine
  @Column({ nullable: true })
  previousStatusActiveTime: number; // How long the machine was in the previous status (in seconds)

  /**
   * The last time the machine was available (i.e. matching machineStatus === MachineStatus.AVAILABLE)
   * So,
   *   if machineStatus == MachineStatus.AVAILABLE, lastAvailableTime is updated to now (same as lastChangeTime)
   *   else lastAvailableTime remains unchanged
   */
  @Column({ type: "timestamp", nullable: true })
  lastAvailableTime: Date;

}
