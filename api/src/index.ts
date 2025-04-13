import { AppDataSource } from "./data-source";
import { User } from "./entity/User";

// src/index.ts
import express, { Express, Request, Response } from "express";
import dotenv from "dotenv";
import fs from "fs";

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

dotenv.config();

const app: Express = express();
app.use(express.json());
const port = process.env.PORT || 3000;

type UpdateData = {
  data: {
    id: number;
    state: number;
  }[];
};
app.post("/api/:orgId/:roomId", (req: Request, res: Response) => {
  const data: UpdateData = req.body;
  const orgId = req.params.orgId;
  const roomId = req.params.roomId;

  console.log(
    `[post/api/:orgId/:roomId] ${orgId}/${roomId} received data:`,
    data
  );

  // append to a file
  const fileName = "update.log";
  const log = data.data
    .map((d) => `(${orgId}/${roomId}) ${d.id} changed to state ${d.state}`)
    .join("\n");
  // add timestamp
  fs.appendFileSync(
    fileName,
    `[${new Date().toISOString()}]${log}\n----------------\n`
  );

  res.send("OK");
});

app.get("/api", (req: Request, res: Response) => {
  res.send("Express + TypeScript Server");
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});
