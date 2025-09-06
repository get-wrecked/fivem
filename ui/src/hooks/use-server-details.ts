/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/hooks/use-server-details.ts
  =====================
  Description:
    The hook for server details context
  ---
  Exports & Exported Components:
    - useServerDetails : The hook for server details context
  ---
  Globals:
    None
*/

import { useContext } from 'react';
import {
    ServerDetailsContext,
    type ServerDetailsContextValue,
} from '@/contexts/server-details-context';

export const useServerDetails = (): ServerDetailsContextValue => {
    const context = useContext(ServerDetailsContext);

    if (!context) {
        throw new Error('useServerDetails must be used within a ServerDetailsProvider.');
    }

    return context;
};
