import "reflect-metadata";
import { DataSource } from "typeorm";
import { Area } from "./models/Area";
import { Room } from "./models/Room";
import { Machine } from "./models/Machine";
import { UpdateEvent } from "./models/UpdateEvent";
import { RawEvent } from "./models/RawEvent";
import { Sensor } from "./models/Sensor";
import { SensorToMachine } from "./models/SensorToMachine";
import * as dotenv from "dotenv";

dotenv.config();

async function checkDatabase() {
  const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5432"),
    username: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || "resiwash",
    synchronize: false,
    logging: false,
    entities: [Area, Room, Machine, UpdateEvent, RawEvent, Sensor, SensorToMachine],
  });

  try {
    await AppDataSource.initialize();
    console.log("Connected to database");

    const areaRepo = AppDataSource.getRepository(Area);
    const roomRepo = AppDataSource.getRepository(Room);
    const machineRepo = AppDataSource.getRepository(Machine);
    const eventRepo = AppDataSource.getRepository(UpdateEvent);

    const areas = await areaRepo.find();
    const rooms = await roomRepo.find();
    const machines = await machineRepo.find();
    const events = await eventRepo.find();

    console.log("\nDatabase contents:");
    console.log("=".repeat(50));
    console.log(`Areas: ${areas.length}`);
    areas.forEach((area) => {
      console.log(`  - ${area.name} (ID: ${area.areaId})`);
    });

    console.log(`\nRooms: ${rooms.length}`);
    rooms.forEach((room) => {
      console.log(`  - ${room.name} (ID: ${room.roomId})`);
    });

    console.log(`\nMachines: ${machines.length}`);
    machines.forEach((machine) => {
      console.log(`  - ${machine.label} (${machine.type}) - ${machine.currentStatus}`);
    });

    console.log(`\nEvents: ${events.length}`);

    if (areas.length === 0) {
      console.log("\nDatabase is empty.");
    } else {
      console.log("\nDatabase has data.");
    }

  } catch (error) {
    console.error("Error connecting to database:", error);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

checkDatabase()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
  });
