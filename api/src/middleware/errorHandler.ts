// middleware/errorHandler.ts
import { Request, Response, NextFunction } from "express";
import { sendErrorResponse } from "../core/responses";

export function errorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  console.error(err); // Log for debugging

  const status = err.statusCode || 500;
  const message = err.message || "Internal Server Error";

  sendErrorResponse(res, err, status);
  
}
