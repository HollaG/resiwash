"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// src/index.ts
const express_1 = __importDefault(require("express"));
const dotenv_1 = __importDefault(require("dotenv"));
const fs_1 = __importDefault(require("fs"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const port = process.env.PORT || 3000;
app.get("/", (req, res) => {
    res.send("Express + TypeScript Server");
});
app.listen(port, () => {
    console.log(`[server]: Server is running at http://localhost:${port}`);
});
app.post("/api/:orgId/:roomId", (req, res) => {
    const data = req.body;
    const orgId = req.params.orgId;
    const roomId = req.params.roomId;
    // append to a file
    const fileName = "update.log";
    const log = data.data.map(d => `${orgId},${roomId},${d.id},${d.state}`).join("\n");
    // add timestamp
    fs_1.default.appendFileSync(fileName, `${new Date().toISOString()}\n${log}\n`);
    res.send("OK");
});
