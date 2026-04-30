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
  manualSetStatus,
  updateMachine,
} from "./machines.controller";
import {
  claimMachine,
  pokeClaimant,
  unclaimMachine,
  updateClaimCycleHandler,
} from "./notifications.controller";

const router = express.Router({ mergeParams: true });

router.get("/", getMachines);
router.get("/:machineId", getMachine);
router.post("/", createMachine);
router.delete("/:machineId", deleteMachine);
router.put("/:machineId", updateMachine);

router.post("/:machineId/claim", claimMachine);
router.post("/:machineId/unclaim", unclaimMachine);
router.post("/:machineId/poke", pokeClaimant);
router.post("/:machineId/update", updateClaimCycleHandler);

router.post("/:machineId/manual", manualSetStatus);

module.exports = router;
