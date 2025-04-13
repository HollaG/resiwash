import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToOne } from "typeorm";
import { Room } from "./Room";

@Entity()
export class Area {
  @PrimaryGeneratedColumn()
  areaId: number;

  @Column()
  name: string;

  @OneToMany(() => Room, (room) => room.area)
  rooms: Room[];

}
