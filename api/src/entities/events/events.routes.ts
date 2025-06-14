/** 
 * Route file: areas.routes.ts
 * Endpoint: /api/v{version}/areas
 */

import express from "express";
import { createEvent, createMultipleEvents, getEvents } from "./events.controller";
import { VerifyToken } from "../../middleware/auth";
const router = express.Router();

router.get("/", getEvents)
router.post("/", VerifyToken, createEvent)
router.post("/bulk", createMultipleEvents)


module.exports = router;