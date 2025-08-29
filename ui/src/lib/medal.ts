interface ClipOptions {
    duration?: number;
    captureDelayMs?: 1000;
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
    const response = await fetch('http://localhost:12665/api/v1/event/invoke', {
        method: 'POST',
        headers: {
            publicKey: key,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
};
