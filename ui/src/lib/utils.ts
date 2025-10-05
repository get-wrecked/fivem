import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merge class names — using Tailwind-aware conflict resolution.
 *
 * @param inputs - Class name values (strings, arrays, objects) as accepted by `clsx`.
 * @returns A single merged class string with Tailwind classes deduplicated.
 */
export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs));
}

/**
 * Remove FiveM ASCII color codes from a string.
 * Color codes follow the pattern ^[0-9] where ^ is followed by a single digit.
 *
 * @param input - The input string containing color codes
 * @returns The string with color codes removed
 */
export const pruneAscii = (input: string): string => {
    return (input ?? '').replace(/\^[0-9]/g, '');
};
