/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/lib/nui.ts
  =====================
  Description:
    NUI helpers for UI to Lua communication
  ---
  Exports & Exported Components:
    - getResourceName : Function to get the resource name
    - nuiPost : Function to POST JSON to a NUI endpoint
    - nuiLog : Function to log via the shared Lua Logger
  ---
  Globals:
    None
*/

import { fetchNui } from '@tsfx/hooks';

/**
 * NUI helpers for UI <-> Lua (CFX) communication.
 *
 * Provides small utilities to communicate from the React UI to client Lua via FiveM's NUI POST callbacks.
 *
 * @packageDocumentation
 */

/**
 * Log levels recognized by the Lua Logger.
 */
export type NuiLogLevel = 'info' | 'error' | 'warning' | 'debug';

/**
 * Log via the shared Lua `Logger` through NUI `ws:log`.
 *
 * @param data - Value or array of values forwarded as logger arguments.
 * @param level - Log level to use on the Lua side. Defaults to `'info'`.
 * @returns A promise resolving with the NUI response, or `null` if unavailable. Falls back to `console.log` on failure.
 * @example
 * await nuiLog('Hello from UI');
 * await nuiLog({ payload: 123 }, 'debug');
 */
export async function nuiLog(data: unknown, level: NuiLogLevel = 'info'): Promise<unknown> {
    const args = Array.isArray(data) ? data : [data];
    const payload = { level, args } as Record<string, unknown>;
    try {
        const res = await fetchNui('ws:log', { payload });
        //=-- Fallback to console when NUI endpoint returns no JSON / not available
        if (res === null) {
            try {
                console.log('[ws:log]', level, ...(args as unknown[]));
            } catch {
                /*//=-- ignore */
            }
        }
        return res as unknown;
    } catch {
        //=-- Fallback to console logging if NUI request fails
        try {
            console.log('[ws:log]', level, ...(args as unknown[]));
        } catch {
            /*//=-- ignore */
        }
        return null as unknown;
    }
}
