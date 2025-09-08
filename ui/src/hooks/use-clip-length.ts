/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/hooks/use-clip-length.ts
  =====================
  Description:
    The hook for clip length context
  ---
  Exports & Exported Components:
    - useClipLength : The hook for clip length context
  ---
  Globals:
    None
*/

import { useContext } from 'react';
import { ClipLengthContext, type ClipLengthContextValue } from '@/contexts/clip-length-context';

export const useClipLength = (): ClipLengthContextValue => {
    const context = useContext(ClipLengthContext);

    if (!context) {
        throw new Error('useClipLength must be used within a ClipLengthProvider');
    }

    return context;
};
