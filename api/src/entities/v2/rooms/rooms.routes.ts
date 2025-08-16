/**
 * Route file: rooms.routes.ts
 * Endpoint: /api/v{version}/rooms
 */

import express from "express";
import {
  createRoom,
  deleteRoom,
  getRoom,
  getRooms,
  updateRoom,
} from "./rooms.controller";
import { VerifyToken } from "../../../middleware/auth";

const router = express.Router({ mergeParams: true });

router.get("/", getRooms);
router.get("/:roomId", getRoom);
router.post("/", VerifyToken, createRoom);
router.delete("/:roomId", VerifyToken, deleteRoom);
router.put("/:roomId", VerifyToken, updateRoom);

module.exports = router;
