import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany } from "typeorm";
import { Room } from "./Room";
import { UpdateEvent } from "./UpdateEvent";


@Entity()
export class Machine {
  @PrimaryGeneratedColumn()
  machineId: number;

  @Column()
  name: string;

  @Column()
  label: string;

  @Column()
  type: string // Washer, Dryer, etc.


  @ManyToOne(() => Room, (room) => room.machines)
  room: Room

  @OneToMany(() => UpdateEvent, (evt) => evt.machine)
  events: UpdateEvent[]
}
