/** 
 * Route file: rooms.routes.ts
 * Endpoint: /api/v{version}/areas/:areaId/:roomId
 */

import express from "express";
import { createMachine, getMachines, getOneMachine } from "./machines.controller";


const router = express.Router({mergeParams: true});

router.get("/", getMachines)
router.post("/", createMachine)
router.get("/:machineId", getOneMachine)


module.exports = router;