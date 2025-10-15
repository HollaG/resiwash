import { User } from "./models/User";

// src/index.ts
import express, { Express, Request, Response } from "express";
const pino = require('pino-http')()
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
import { sendErrorResponse } from "./core/responses";

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
app.use(pino);
const port = process.env.PORT || 3000;

// ROUTES
app.get("/", (req: Request, res: Response) => {
  res.send("Hello World!");
});

const API_VERSION = process.env.API_VERSION || "v1";

const API_VERSIONS = ["v1", "v2"];

// ------ API v1 Routes ------

// Machines
app.use(
  `/api/v1/areas/:areaId/:roomId`,
  require("./entities/v1/machines/machines.routes")
);

// Rooms
app.use(`/api/v1/areas/:areaId`, require("./entities/v1/rooms/rooms.routes"));

// Areas
app.use(
  `/api/v1/areas`,
  VerifyToken,
  require("./entities/v1/areas/areas.routes")
);

// Locations
app.use(
  `/api/v1/locations`,
  require("./entities/v1/locations/locations.routes")
);

// Events
app.use(`/api/v1/events`, require("./entities/v1/events/events.routes"));

// Sensors
app.use(`/api/v1/sensors`, require("./entities/v1/sensors/sensors.routes"));

// API v2 Routes
// Areas
app.use(
  `/api/v2/areas`,
  VerifyToken,
  require("./entities/v2/areas/areas.routes")
);

// Rooms
app.use(`/api/v2/rooms`, require("./entities/v2/rooms/rooms.routes"));

// Machines
app.use(`/api/v2/machines`, require("./entities/v2/machines/machines.routes"));

// Locations
app.use(
  `/api/v2/locations`,
  require("./entities/v2/locations/locations.routes")
);

// Events
app.use(`/api/v2/events`, require("./entities/v2/events/events.routes"));

// Sensors
app.use(`/api/v2/sensors`, require("./entities/v2/sensors/sensors.routes"));

// error handler (last)
app.use(errorHandler);

app.get("/api", (req: Request, res: Response) => {
  res.send("Express + TypeScript Server");
});
app.get("/api/checkAuth", VerifyToken, (req: Request, res: Response) => {
  res.send("Express + TypeScript Server Auth works");
});

// catch-all, return error: invalid url
app.get("*", (req: Request, res: Response) => {
  sendErrorResponse(res, { message: "invalid url" }, 404);
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});
