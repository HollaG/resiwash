/** 
 * Route file: rooms.routes.ts
 * Endpoint: /api/v{version}/areas/:areaId
 */

import express from "express";
import { createRoom, deleteRoom, getRooms } from "./rooms.controller";
import { VerifyToken } from "../../middleware/auth";

const router = express.Router({mergeParams: true});

router.delete("/:id", VerifyToken, deleteRoom);
router.get("/", getRooms)
router.post("/", VerifyToken, createRoom)


module.exports = router;