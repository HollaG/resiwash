import auth from "../core/firebase";
import { sendErrorResponse } from "../core/responses";

export const VerifyToken = async (req, res, next) => {
  if (
    !req.headers.authorization ||
    !req.headers.authorization.startsWith("Bearer ")
  ) {
    return sendErrorResponse(res, "Unauthorized", 401);
  }
  const split = req.headers.authorization.split(" ");
  if (split.length !== 2 || split[0] !== "Bearer") {
    return sendErrorResponse(res, "Unauthorized", 401);
  }
  const token = req.headers.authorization.split(" ")[1];

  try {
    const decodeValue = await auth.verifyIdToken(token);
    if (decodeValue) {
      req.user = decodeValue;
      return next();
    }
  } catch (e) {
    return sendErrorResponse(res, "Unauthorized", 401);
  }
};
