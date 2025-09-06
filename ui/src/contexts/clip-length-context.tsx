/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/contexts/clip-length-context.tsx
  =====================
  Description:
    The clip length context for the UI
  ---
  Exports & Exported Components:
    - ClipLengthContext : The clip length context
    - ClipLengthContextValue : The clip length context's value interface
  ---
  Globals:
    None
*/

import { createContext } from 'react';

export interface ClipLengthContextValue {
    length: string;
    setLength: (length: string) => void;
}

export const ClipLengthContext = createContext<ClipLengthContextValue>({
    length: '30',
    setLength: () => {
        console.error('Failed to set clip length. The context has not been initialized.');
    },
});
