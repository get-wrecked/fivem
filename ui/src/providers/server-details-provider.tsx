import { useNuiEvent } from '@tsfx/hooks';
import type React from 'react';
import { type PropsWithChildren, useState } from 'react';
import {
    ServerDetailsContext,
    type ServerDetailsContextValue,
} from '@/contexts/server-details-context';

export interface ServerDetailsProviderProps {
    context?: React.Context<ServerDetailsContextValue>;
    initialName?: string;
    initialIconUrl?: string;
}

export const ServerDetailsProvider: React.FC<PropsWithChildren<ServerDetailsProviderProps>> = ({
    children,
    context = ServerDetailsContext,
    initialName = 'FXServer',
    initialIconUrl = 'https://cdn.medal.tv/assets/img/fivem.icon-default.oMr5K.png',
}) => {
    const [name, setName] = useState<string>(initialName);
    const [iconUrl, setIconUrl] = useState<string>(initialIconUrl);

    useNuiEvent<string>('ac:details', {
        handler: async (id) => {
            const response = await fetch(
                `https://servers-frontend.fivem.net/api/servers/single/${id}`,
            );

            const serverData = await response.json();
            const iconVersion = serverData['Data']['iconVersion'];
            const projectName = serverData['Data']['vars']['sv_projectName'];
            const hostName = serverData['Data']['hostname'];

            setName(projectName ?? hostName);

            if (iconVersion) {
                setIconUrl(`https://servers-live.fivem.net/servers/icon/${id}/${iconVersion}.png`);
            }
        },
    });

    return <context.Provider value={{ name, iconUrl }}>{children}</context.Provider>;
};
