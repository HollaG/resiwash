/**
 * Route file: locations.routes.ts
 * Endpoint: /api/v{version}/locations
 */

import express from "express";
import { getLocations } from "./locations.controller";
const router = express.Router();

router.get("/", getLocations);

module.exports = router;
