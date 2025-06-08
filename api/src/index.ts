import { User } from "./models/User";

// src/index.ts
import express, { Express, Request, Response } from "express";
import dotenv from "dotenv";
import fs from "fs";
import session from "express-session";
import { errorHandler } from "./middleware/errorHandler";
import cors from "cors";
import admin from "firebase-admin";

import cookieParser from "cookie-parser";

dotenv.config();

import { AppDataSource } from "./data-source";
import { VerifyToken } from "./middleware/auth";

// TypeORM
AppDataSource.initialize()
  .then(async () => {
    console.log("Inserting a new user into the database...");
    const user = new User();
    user.firstName = "Timber";
    user.lastName = "Saw";
    user.age = 25;
    await AppDataSource.manager.save(user);
    console.log("Saved a new user with id: " + user.id);

    console.log("Loading users from the database...");
    const users = await AppDataSource.manager.find(User);
    console.log("Loaded users: ", users);

    console.log(
      "Here you can setup and run express / fastify / any other framework."
    );
  })
  .catch((error) => console.log(error));

const app: Express = express();
app.use(express.json());
app.use(cors());
app.use(cookieParser());
app.use(
  session({
    secret: process.env.SESSION_KEY,
    resave: true,
    saveUninitialized: true,
  })
);
const port = process.env.PORT || 3000;

// ROUTES
app.get("/", (req: Request, res: Response) => {
  res.send("Hello World!");
});

const API_VERSION = process.env.API_VERSION || "v1";

// Machines
app.use(
  `/api/${API_VERSION}/areas/:areaId/:roomId`,
  require("./entities/machines/machines.routes")
);

// Rooms
app.use(
  `/api/${API_VERSION}/areas/:areaId`,
  require("./entities/rooms/rooms.routes")
);


// Areas
app.use(
  `/api/${API_VERSION}/areas`,
  VerifyToken,
  require("./entities/areas/areas.routes")
);



// Events
app.use(
  `/api/${API_VERSION}/events`,
  require("./entities/events/events.routes")
);

// Sensors
app.use(
  `/api/${API_VERSION}/sensors`,
  VerifyToken,
  require("./entities/sensors/sensors.routes")
);

// error handler (last)
app.use(errorHandler);

app.get("/api", (req: Request, res: Response) => {
  res.send("Express + TypeScript Server");
});
app.get("/api/checkAuth", VerifyToken, (req: Request, res: Response) => {
  res.send("Express + TypeScript Server Auth works");
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});
