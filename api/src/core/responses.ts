import { Response } from 'express';

/**
 * Sends a 200 OK response with the given payload.
 * 
 * @param res Pass on the response object from express
 * @param payload any object to be sent as a response
 */
export const sendOkResponse = (res: Response, payload: any & { message?: string }) => {
  res.status(200).json({
    status: 'success',
    data: payload,
  });
}

export const sendErrorResponse = (res: Response, error: any, code: number = 500) => {
  res.status(code).json({
    status: 'error',
    error
  });
}