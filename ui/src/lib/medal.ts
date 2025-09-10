/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/lib/medal.ts
  =====================
  Description:
    Medal.tv Recorder client API functions for the UI/NUI
  ---
  Exports & Exported Components:
    - triggerClip : a function to trigger a clip with the Medal.tv Recorder client
  ---
  Globals:
    None
*/

interface ClipOptions {
    duration?: number;
    captureDelayMs?: number;
    alertType?: 'Default' | 'Disabled' | 'SoundOnly' | 'OverlayOnly';
}

interface OtherPlayers {
    playerId: string;
    playerName: string;
}

export interface ClipData {
    eventId: string;
    eventName: string;
    otherPlayers?: OtherPlayers[];
    contextTags?: { [key: string]: string };
    triggerActions?: ('SaveClip' | 'SaveScreenshot')[];
    clipOptions?: ClipOptions;
}

export interface ScreenshotData {
    mimeType: string;
}

export interface ScreenshotResponse {
    status: string;
    imageBase64: string;
    mimeType: string;
}

const MEDAL_KEY = 'pub_82qkpMKV77AkpqLSgWsxLlDyfzpPI7Vw';

const buildHeaders = (method: string = 'GET', body?: ClipData | ScreenshotData): RequestInit => {
    return {
        method,
        headers: {
            publicKey: MEDAL_KEY,
            'Content-Type': 'application/json',
        },
        body: body ? JSON.stringify(body) : undefined,
    };
};

export const triggerClip = async (data: ClipData): Promise<void> => {
    try {
        const response = await fetch(
            'http://localhost:12665/api/v1/event/invoke',
            buildHeaders('POST', data),
        );

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(
                `Failed to trigger clip: ${response.status} ${response.statusText} - ${errorText}`,
            );
        }
    } catch (error) {
        console.error('Network error while triggering clip:', error);
    }
};

export const hasMedal = async (): Promise<boolean> => {
    try {
        const response = await fetch('http://localhost:12665/api/v1/user/profile', buildHeaders());

        return response.ok;
    } catch (_err) {
        return false;
    }
};

export const screenshot = async (mimeType: string): Promise<string> => {
    try {
        const params = new URLSearchParams({ format: mimeType });
        const response = await fetch(
            `http://localhost:12665/api/v1/screenshot/base64?${params}`,
            buildHeaders(),
        );

        if (!response.ok) {
            const errorText = await response.text();

            throw new Error(
                `Failed to return base64 screenshot: ${response.status} ${response.statusText} - ${errorText}`,
            );
        }

        const result = (await response.json()) as ScreenshotResponse;

        return result.imageBase64;
    } catch (error) {
        console.error('Network error while retrieving base64 screenshot:', error);
        return '';
    }
};
