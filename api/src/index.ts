// src/index.ts
import express, { Express, Request, Response } from "express";
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

const app: Express = express();
app.use(express.json());
const port = process.env.PORT || 3000;

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
  const log = data.data.map(d => `(${orgId}/${roomId}) ${d.id} changed to state ${d.state}`).join("\n");
  // add timestamp
  fs.appendFileSync(fileName, `[${new Date().toISOString()}]${log}\n----------------\n`);

  res.send("OK");

})

app.get("/api", (req: Request, res: Response) => {
  res.send("Express + TypeScript Server");
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});

