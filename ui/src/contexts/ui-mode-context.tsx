import { createContext } from 'react';

export type UiMode = 'closed' | 'slideover' | 'reporting';

export interface UiModeContextValue {
    mode: UiMode;
    setMode: (mode: UiMode) => void;
    openSlideover: () => void;
    openReporting: () => void;
    closeAll: () => void;
}

export const UiModeContext = createContext<UiModeContextValue>({
    mode: 'closed',
    setMode: () => {
        console.error('Failed to set UI mode. The context has not been initialized.');
    },
    openSlideover: () => {
        console.error('Failed to opne slideober. The context has not been initialized.');
    },
    openReporting: () => {
        console.error('Failed to open reporting. The context has not been initialized.');
    },
    closeAll: () => {
        console.error('Failed to close UI. The context has not been initialized.');
    },
});
