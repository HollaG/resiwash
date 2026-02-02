import "reflect-metadata"
import { DataSource } from "typeorm"
import { User } from "./models/User"
import { Area } from "./models/Area"
import { Machine } from "./models/Machine"
import { Room } from "./models/Room"
import { Sensor } from "./models/Sensor"
import { UpdateEvent } from "./models/UpdateEvent"
import { RawEvent } from "./models/RawEvent"
import { SensorToMachine } from "./models/SensorToMachine"

export const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5432"),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD || undefined,
    database: process.env.DB_NAME,
    synchronize: true,
    logging: false,
    entities: [Area, Machine, Room, Sensor, UpdateEvent, User, RawEvent, SensorToMachine],
    migrations: [],
    subscribers: [],
})
