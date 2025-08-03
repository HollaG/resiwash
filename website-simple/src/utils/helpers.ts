import { BASE_URL } from "../types/enums";

/**
 * Returns a greeting based on the current time of day
 * @returns "Good morning!" for 3 AM - 12 PM, "Good afternoon!" for 12 PM - 6 PM, "Good evening!" for 6 PM - 3 AM
 */
export function getTimeBasedGreeting(): string {
  const now = new Date();
  const hour = now.getHours();

  if (hour >= 3 && hour < 12) {
    return "Good morning!";
  } else if (hour >= 12 && hour < 18) {
    return "Good afternoon!";
  } else {
    // 6 PM (18:00) to 3 AM (covers 18-23 and 0-2)
    return "Good evening!";
  }
}

export const urlBuilder = (resourceUrl: string) => {
  return `${BASE_URL}/${resourceUrl}`;
};
