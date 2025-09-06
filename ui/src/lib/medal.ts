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

export const triggerClip = async (key: string, data: ClipData): Promise<void> => {
    try {
        const response = await fetch('http://localhost:12665/api/v1/event/invoke', {
            method: 'POST',
            headers: {
                publicKey: key,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });

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
