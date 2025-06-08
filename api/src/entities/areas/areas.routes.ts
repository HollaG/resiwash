/** 
 * Route file: areas.routes.ts
 * Endpoint: /api/v{version}/areas
 */

import express from "express";
import { createArea, deleteArea, getAreas } from "./areas.controller";
const router = express.Router();

router.delete("/:id", deleteArea);
router.get("/", getAreas)
router.post("/", createArea)


module.exports = router;