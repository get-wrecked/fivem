import { createContext } from 'react';

export interface ServerDetailsContextValue {
    name: string;
    iconUrl: string;
}

export const ServerDetailsContext = createContext<ServerDetailsContextValue>({
    name: 'FXServer',
    iconUrl: 'https://cdn.medal.tv/assets/img/fivem.icon-default.oMr5K.png',
});
