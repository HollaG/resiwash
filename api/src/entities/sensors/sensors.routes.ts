/** 
 * Route file: sensors.routes.ts
 * Endpoint: /api/v{version}/sensors
 */

import express from "express";
import { deleteSensorLink, getSensorLinks, getSensors, registerSensor, setSensorApiKey, setSensorLink } from "./sensors.controller";


const router = express.Router({mergeParams: true});

// router.delete("/:id", deleteRoom);
// router.get("/", getRooms)
// router.post("/", createRoom)

router.get("/", getSensors)
router.post("/register", registerSensor);
router.post("/:id", setSensorApiKey)
router.get("/link/:id", getSensorLinks)
router.post('/link/:id', setSensorLink)
router.delete('/link/:id', deleteSensorLink)


module.exports = router;