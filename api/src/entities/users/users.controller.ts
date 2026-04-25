import { Request, Response } from "express";
import asyncHandler from "express-async-handler";
import { AppDataSource } from "../../data-source";
import { sendErrorResponse, sendOkResponse } from "../../core/responses";
import { User } from "../../models/User";

type CreateUserBody = {
  name?: string;
  fcmToken?: string;
};

export const createUser = asyncHandler(
  async (req: Request<unknown, unknown, CreateUserBody>, res: Response) => {
    const { name, fcmToken } = req.body;

    if (!name || typeof name !== "string" || name.trim().length === 0) {
      return sendErrorResponse(res, { message: "name is required" }, 400);
    }

    if (
      !fcmToken ||
      typeof fcmToken !== "string" ||
      fcmToken.trim().length === 0
    ) {
      return sendErrorResponse(res, { message: "fcmToken is required" }, 400);
    }

    const userRepository = AppDataSource.getRepository(User);

    const user = new User();
    user.name = name.trim();
    user.fcmToken = fcmToken.trim();

    const savedUser = await userRepository.save(user);

    sendOkResponse(res, savedUser);
  },
);
