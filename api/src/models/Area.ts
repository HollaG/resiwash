import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";
import { Room } from "./Room";

@Entity()
export class Area {
  @PrimaryGeneratedColumn()
  areaId: number;

  @Column()
  name: string;

  @Column({nullable: true})
  location: string; // e.g., "Ridge View Residential College"

  @Column({nullable: true})
  description: string; // e.g., "Ridge View Residential College is a residential college located in the heart of the university campus."

  @Column({nullable: true})
  imageUrl: string; // e.g., "https://example.com/image.jpg"

  @Column({nullable: true})
  shortName: string; // e.g., "RVRC"  

  @OneToMany(() => Room, (room) => room.area)
  rooms: Room[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
