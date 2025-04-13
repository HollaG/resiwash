import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany } from "typeorm";
import { Area } from "./Area";
import { Machine } from "./Machine";
import { Sensor } from "./Sensor";

@Entity()
export class Room {
  @PrimaryGeneratedColumn()
  roomId: number;

  @Column()
  name: string;

  @Column()
  location: string;

  @ManyToOne(() => Area, (area) => area.areaId)
  area: Area;

  @OneToMany(() => Machine, (machine) => machine.room)
  machines: Machine[];

  @OneToMany(() => Sensor, (sensor) => sensor.room)
  sensors: Sensor[];
}
