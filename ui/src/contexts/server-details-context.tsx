/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/contexts/server-details-context.tsx
  =====================
  Description:
    The server details context for the UI
  ---
  Exports & Exported Components:
    - ServerDetailsContext : The server details context 
    - ServerDetailsContextValue : The server details context's value interface
  ---
  Globals:
    None
*/

import { createContext } from 'react';

export interface ServerDetailsContextValue {
    name: string;
    iconUrl: string;
}

export const ServerDetailsContext = createContext<ServerDetailsContextValue>({
    name: 'FXServer',
    iconUrl: 'https://cdn.medal.tv/assets/img/fivem.icon-default.oMr5K.png',
});
