import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";
import { Room } from "./Room";

@Entity()
export class Sensor {
  @PrimaryGeneratedColumn()
  sensorId: number;

  @ManyToOne(() => Room, (room) => room.sensors)
  @JoinColumn({ name: "roomId" })
  room: Room;

  @Column()
  macAddress: string;

  @Column({nullable: true})
  apiKey: string; // hashed

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
