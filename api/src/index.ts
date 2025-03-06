// src/index.ts
import express, { Express, Request, Response } from "express";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const app: Express = express();
const port = process.env.PORT || 3000;

app.get("/", (req: Request, res: Response) => {
  res.send("Express + TypeScript Server");
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});

type UpdateData = {
  data: {
    id: string;
    state: number
  }[]
};
app.post("/api/:orgId/:roomId", (req: Request, res: Response) => {
  const data: UpdateData = req.body;
  const orgId = req.params.orgId;
  const roomId = req.params.roomId;

  // append to a file
  const fileName = "update.log"
  const log = data.data.map(d => `${orgId},${roomId},${d.id},${d.state}`).join("\n");
  // add timestamp
  fs.appendFileSync(fileName, `${new Date().toISOString()}\n${log}\n`);
  res.send("OK");

})