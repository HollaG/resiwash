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
import { Area } from "./Area";
import { Machine } from "./Machine";
import { Sensor } from "./Sensor";

@Entity()
export class Room {
  @PrimaryGeneratedColumn()
  roomId: number;

  @Column()
  name: string;

  @Column({nullable: true})
  location: string;

  @Column({nullable: true})
  description: string;

  @Column({nullable: true})
  imageUrl: string;

  @Column({nullable: true})
  shortName: string; // e.g., "RVRC"

  @ManyToOne(() => Area, (area) => area.rooms)
  @JoinColumn({ name: "areaId" })
  area: Area;

  @OneToMany(() => Machine, (machine) => machine.room)
  machines: Machine[];

  @OneToMany(() => Sensor, (sensor) => sensor.room)
  sensors: Sensor[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
