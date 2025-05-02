/** 
 * Route file: areas.routes.ts
 * Endpoint: /api/v{version}/areas
 */

import express from "express";
import { createEvent, createMultipleEvents, getEvents } from "./events.controller";
const router = express.Router();

router.get("/", getEvents)
router.post("/", createEvent)
router.post("/bulk", createMultipleEvents)


module.exports = router;