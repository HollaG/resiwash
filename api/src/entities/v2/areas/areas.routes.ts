/**
 * Route file: areas.routes.ts
 * Endpoint: /api/v{version}/areas
 */

import express from "express";
import {
  createArea,
  deleteArea,
  getArea,
  getAreas,
  updateArea,
} from "./areas.controller";
const router = express.Router();

router.get("/", getAreas);
router.get("/:areaId", getArea);
router.delete("/:areaId", deleteArea);
router.post("/", createArea);
router.put("/:areaId", updateArea);

module.exports = router;
