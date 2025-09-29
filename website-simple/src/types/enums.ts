// export enum Status {
//   UNKNOWN = "Unknown",
//   AVAILABLE = "Available",
//   IN_USE = "In Use",
// }

// export const StatusCodeToEnumMap = {
//   "0": Status.AVAILABLE,
//   "1": Status.IN_USE,
//   "-1": Status.UNKNOWN,
// };

// export const statusCodeToEnum = (statusCode: number): Status => {
//   switch (statusCode) {
//     case 0:
//       return Status.AVAILABLE;
//     case 1:
//       return Status.IN_USE;
//     default:
//       return Status.UNKNOWN;
//   }
// };

export enum Pages {
  HOME = "",
  ADMIN = "admin",
}

export const BASE_URL =
  import.meta.env.VITE_BASE_URL || "http://localhost:3000/api/v2";
