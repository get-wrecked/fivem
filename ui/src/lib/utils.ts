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
