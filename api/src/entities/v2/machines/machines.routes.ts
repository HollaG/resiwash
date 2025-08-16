/**
 * Route file: rooms.routes.ts
 * Endpoint: /api/v{version}/machines
 */

import express from "express";
import {
  createMachine,
  deleteMachine,
  getMachine,
  getMachines,
  updateMachine,
} from "./machines.controller";

const router = express.Router({ mergeParams: true });

router.get("/", getMachines);
router.get("/:machineId", getMachine);
router.post("/", createMachine);
router.delete("/:machineId", deleteMachine);
router.put("/:machineId", updateMachine);

module.exports = router;
