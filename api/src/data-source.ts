import "reflect-metadata";
import dotenv from "dotenv";
import { DataSource } from "typeorm";
import { User } from "./models/User";
import { Area } from "./models/Area";
import { Machine } from "./models/Machine";
import { Room } from "./models/Room";
import { Sensor } from "./models/Sensor";
import { UpdateEvent } from "./models/UpdateEvent";
import { RawEvent } from "./models/RawEvent";
import { SensorToMachine } from "./models/SensorToMachine";
import { Claim } from "./models/Claim";
import { LastPoke } from "./models/LastPoke";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD ?? "",
  database: process.env.DB_NAME,
  synchronize: false,
  logging: false,
  entities: [
    Area,
    Machine,
    Room,
    Sensor,
    UpdateEvent,
    User,
    RawEvent,
    SensorToMachine,
    Claim,
    LastPoke,
  ],
  migrations: [__dirname + "/migration/*.{ts,js}"],
  subscribers: [],
});
