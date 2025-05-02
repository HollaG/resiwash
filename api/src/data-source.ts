import "reflect-metadata"
import { DataSource } from "typeorm"
import { User } from "./models/User"
import { Area } from "./models/Area"
import { Machine } from "./models/Machine"
import { Room } from "./models/Room"
import { Sensor } from "./models/Sensor"
import { UpdateEvent } from "./models/UpdateEvent"

export const AppDataSource = new DataSource({
    type: "postgres",
    host: "localhost",
    port: 5432,
    username: "laundryapi",
    password: "laundryapi123",
    database: "laundry",
    synchronize: true,
    logging: false,
    entities: [Area, Machine, Room, Sensor, UpdateEvent, User],
    migrations: [],
    subscribers: [],
})
