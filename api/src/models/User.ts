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

  @Column()
  name: string;

  @CreateDateColumn()
  createDate: Date;

  // Other providers
  @Column({ nullable: true })
  telegramId?: string;
}
