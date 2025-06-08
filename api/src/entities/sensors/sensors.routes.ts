/**
 * Route file: sensors.routes.ts
 * Endpoint: /api/v{version}/sensors
 */

import express from "express";
import {
  deleteSensorLink,
  getSensorLinks,
  getSensors,
  registerSensor,
  setSensorApiKey,
  setSensorLink,
} from "./sensors.controller";
import { VerifyToken } from "../../middleware/auth";

const router = express.Router({ mergeParams: true });

// router.delete("/:id", deleteRoom);
// router.get("/", getRooms)
// router.post("/", createRoom)

router.get("/", VerifyToken, getSensors);
router.post("/register", registerSensor);
router.post("/:id", VerifyToken, setSensorApiKey);
router.get("/link/:id", VerifyToken, getSensorLinks);
router.post("/link/:id", VerifyToken, setSensorLink);
router.delete("/link/:id", VerifyToken, deleteSensorLink);

module.exports = router;
