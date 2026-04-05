import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from "typeorm";
import { Machine } from "./Machine";

@Entity()
export class Claim {
  @PrimaryGeneratedColumn()
  claimId: number;

  @Column({ select: false }) // this is a PRIVATE field. do NOT leak to frontend
  fcmToken: string;

  @Column()
  cycleTime: number; //minutes

  // Explicit column allows direct ID assignment (claim.machineId = 123)
  // without needing to load the full Machine relation first
  @Column()
  machineId: number;

  @ManyToOne(() => Machine, (machine) => machine.machineId)
  @JoinColumn({ name: "machineId" })
  machine: Machine;

  @CreateDateColumn()
  claimedAt: Date;

  @Column({ type: "timestamp", nullable: true })
  completedAt: Date;

  @Column({ type: "timestamp", nullable: true })
  unclaimedAt: Date;
}
