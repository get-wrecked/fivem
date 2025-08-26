import { createContext } from 'react';

export interface ServerDetailsContextValue {
    name: string;
    iconUrl: string;
    setName: (name: string) => void;
    setIconUrl: (iconUrl: string) => void;
}

export const ServerDetailsContext = createContext<ServerDetailsContextValue>({
    name: 'FXServer',
    iconUrl: 'https://cdn.medal.tv/assets/img/fivem.icon-default.oMr5K.png',
    setName: () => {
        console.error('Failed to set server details name. The context has not been initialized.');
    },
    setIconUrl: () => {
        console.error(
            'Failed to set server details icon url. The context has not been initialized.',
        );
    },
});
