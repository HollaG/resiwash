/**
 * Route file: admin.routes.ts
 * Endpoint: /api/v{version}/admin
 */

import express from "express";
import { sendDebugNotification } from "./admin.controller";
const router = express.Router();

router.post("/send-debug-notification", sendDebugNotification);

module.exports = router;
