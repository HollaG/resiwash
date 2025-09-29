/**
 * Route file: sensors.routes.ts
 * Endpoint: /api/v{version}/sensors
 */

import express from "express";
import {
  deleteSensorLink,
  getSensor,
  getSensorLinks,
  getSensors,
  registerSensor,
  setSensorApiKey,
  setSensorLink,
} from "./sensors.controller";
import { VerifyToken } from "../../../middleware/auth";

const router = express.Router({ mergeParams: true });

// router.delete("/:id", deleteRoom);
// router.get("/", getRooms)
// router.post("/", createRoom)

router.get("/", VerifyToken, getSensors);
router.post("/register", registerSensor);
router.post("/:id", VerifyToken, setSensorApiKey);
router.get("/:id", VerifyToken, getSensor);

router.get("/:id/link", VerifyToken, getSensorLinks);
router.post("/:id/link", VerifyToken, setSensorLink);
router.delete("/:id/link", VerifyToken, deleteSensorLink);

module.exports = router;
