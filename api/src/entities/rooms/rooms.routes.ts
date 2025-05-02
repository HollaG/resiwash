/** 
 * Route file: rooms.routes.ts
 * Endpoint: /api/v{version}/areas/:areaId
 */

import express from "express";
import { createRoom, getRooms } from "./rooms.controller";

const router = express.Router({mergeParams: true});

router.get("/", getRooms)
router.post("/", createRoom)


module.exports = router;