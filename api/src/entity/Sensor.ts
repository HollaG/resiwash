import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne, PrimaryColumn } from "typeorm";
import { Room } from "./Room";

@Entity()
export class Sensor {
  @PrimaryGeneratedColumn()
  sensorId: number;

  @PrimaryColumn()
  @ManyToOne(() => Room, (room) => room.sensors)
  room: Room;




}
