import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merges Tailwind CSS classes with proper precedence handling
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
