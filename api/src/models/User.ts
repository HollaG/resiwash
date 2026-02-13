import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from "typeorm";

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  userId: number;

  @Column()
  fcmToken: string;

  @Column({ nullable: true })
  name?: string;

  @CreateDateColumn()
  createDate: Date;
}
