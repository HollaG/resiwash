import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from "typeorm";
import { Room } from "./Room";
import { SensorToMachine } from "./SensorToMachine";

@Entity()
export class Sensor {
  @PrimaryGeneratedColumn()
  sensorId: number;

  @ManyToOne(() => Room, (room) => room.sensors)
  @JoinColumn({ name: "roomId" })
  room: Room;

  @OneToMany(() => SensorToMachine, (sensorToMachine) => sensorToMachine.sensor)
  sensorToMachines: SensorToMachine[];

  @Column()
  macAddress: string;

  @Column({ nullable: true })
  apiKey: string; // hashed

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
