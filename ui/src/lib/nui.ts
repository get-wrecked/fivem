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

/**
 * NUI helpers for UI <-> Lua (CFX) communication.
 *
 * Provides small utilities to communicate from the React UI to client Lua via FiveM's NUI POST callbacks.
 *
 * @packageDocumentation
 */

/**
 * Get the current resource name from FiveM's NUI environment, with a sensible fallback.
 *
 * @remarks
 * This is `GetParentResourceName()` with fallbacks.
 *
 * @returns The resolved resource name (e.g., `"medal--fivem-resource"`).
 * @example
 * const resource = getResourceName();
 * console.log(resource);
 */
export function getResourceName(): string {
    const w = window as any;
    return typeof w.GetParentResourceName === 'function'
        ? w.GetParentResourceName()
        : 'medal--fivem-resource';
}

/**
 * Log levels recognized by the Lua Logger.
 */
export type NuiLogLevel = 'info' | 'error' | 'warning' | 'debug';

/**
 * POST JSON to a NUI endpoint and attempt to parse a JSON response.
 *
 * @typeParam T - Expected JSON response. Returns like `T | null`.
 * @param endpoint - The NUI callback endpoint name (e.g., `"ws:minecart"`).
 * @param body - Optional payload to JSONify. Default = empty object.
 * @returns Parsed JSON as `T` if available, otherwise `null` when the endpoint returns no JSON or parsing fails.
 * @example
 * const ore = await nuiPost<{ name: string; communityName: string }>('ws:minecart', { type: 'heartbeat' });
 * if (ore) {
 *   console.log(ore.name, ore.communityName);
 * }
 */
export async function nuiPost<T = unknown>(endpoint: string, body?: unknown): Promise<T | null> {
    const resource = getResourceName();
    try {
        const res = await fetch(`https://${resource}/${endpoint}`, {
            // TODO: Swap to fetchNui?
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body ?? {}),
        });
        //=-- Maybe not every NUI endpoint returns JSON; kill off the errors
        return (await res.json().catch(() => null)) as T | null;
    } catch {
        return null;
    }
}

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
        const res = await nuiPost('ws:log', payload);
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
