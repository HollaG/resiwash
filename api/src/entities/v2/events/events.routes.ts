/**
 * Route file: events.routes.ts
 * Endpoint: /api/v{version}/events
 */

import express from "express";
import {
  createEvent,
  createMultipleEvents,
  getEvents,
  getEventsFormatted,
} from "./events.controller";
import { VerifyToken } from "../../../middleware/auth";
const router = express.Router();

router.get("/", getEvents);
router.get("/formatted", getEventsFormatted);
router.post("/", VerifyToken, createEvent);
router.post("/bulk", createMultipleEvents);

module.exports = router;
