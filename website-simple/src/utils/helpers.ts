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

export type MachineLike = {
  label: string;
  type?: string;
  name?: string;
};

export const getMachineSlotKey = ({ label, type, name }: MachineLike): string | null => {
  const forcedPrefix = type === 'washer' ? 'W' : type === 'dryer' ? 'D' : undefined;

  // When we know the type, only consider explicit W#/D# tokens.
  // This avoids accidentally using unrelated digits in strings like "RVRTL8 W1".
  if (forcedPrefix) {
    const sources = [name, label].filter(Boolean) as string[];
    for (const source of sources) {
      const match = source.match(new RegExp(`${forcedPrefix}\\s*0*(\\d+)`, 'i'));
      if (match) {
        const number = parseInt(match[1], 10);
        if (!Number.isNaN(number)) return `${forcedPrefix}${number}`;
      }
    }

    return null;
  }

  // If we don't know the type, fall back to a simple letter+number parse from
  // the last dashed token (e.g. "RVTWR-D01" -> "D1").
  const lastToken = label.split('-').pop() || label;
  const match = lastToken.match(/([A-Za-z])\s*0*(\d+)/);
  if (!match) return null;

  const prefix = match[1].toUpperCase();
  const number = parseInt(match[2], 10);
  if (Number.isNaN(number)) return null;

  return `${prefix}${number}`;
};

export const getMachineSlotNumber = (machine: MachineLike): number | null => {
  const key = getMachineSlotKey(machine);
  if (!key) return null;

  const match = key.match(/(\d+)/);
  if (!match) return null;

  const number = parseInt(match[1], 10);
  return Number.isNaN(number) ? null : number;
};

export const shortMachineLabel = (label: string, type?: string, name?: string) => {
  return getMachineSlotKey({ label, type, name }) ?? label;
};
