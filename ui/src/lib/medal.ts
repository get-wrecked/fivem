/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/lib/medal.ts
  =====================
  Description:
    Medal.tv Recorder client API functions for the UI/NUI
  ---
  Exports & Exported Components:
    - Medal: Api wrapper for Medal desktop client local game API
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

class Medal {
    private static readonly API_KEY: string = 'pub_82qkpMKV77AkpqLSgWsxLlDyfzpPI7Vw';
    private static readonly BASE_URL: string = 'http://localhost:12665/api/v1/';

    private buildHeaders(method: string = 'GET', body?: ClipData | ScreenshotData): RequestInit {
        return {
            method,
            headers: {
                publicKey: Medal.API_KEY,
                'Content-Type': 'application/json',
            },
            body: body ? JSON.stringify(body) : undefined,
        };
    }

    private buildUrl(uri: string, parameters?: Record<string, string>): URL {
        const params = new URLSearchParams(parameters || {});
        const url = new URL(uri, Medal.BASE_URL);
        url.search = params.toString();

        return url;
    }

    private async request(
        uri: string,
        options?: {
            method?: string;
            body?: ClipData | ScreenshotData;
            parameters?: Record<string, string>;
        },
    ): Promise<Response> {
        const url = this.buildUrl(uri, options?.parameters);
        const init = this.buildHeaders(options?.method, options?.body);

        return fetch(url, init);
    }

    public async triggerClip(data: ClipData): Promise<void> {
        try {
            const response = await this.request('event/invoke', { method: 'POST', body: data });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(
                    `Failed to trigger clip: ${response.status} ${response.statusText} - ${errorText}`,
                );
            }
        } catch (error) {
            console.error('Network error while triggering clip:', error);
        }
    }

    public async hasApp(): Promise<boolean> {
        try {
            const response = await this.request('user/profile');

            return response.ok;
        } catch (_err) {
            return false;
        }
    }

    public async screenshot(mimeType: string): Promise<string> {
        try {
            const response = await this.request('screenshot/base64', {
                parameters: { format: mimeType },
            });

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
    }
}

const medal = new Medal();
export { medal as Medal };
