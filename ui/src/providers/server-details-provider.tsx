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

interface ServerDetailsResponse {
    Data: {
        iconVersion: number;
        hostname: string;
        vars: {
            sv_projectName: string;
        };
    };
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
            try {
                const response = await fetch(
                    `https://servers-frontend.fivem.net/api/servers/single/${id}`,
                );

                if (!response.ok) {
                    throw new Error(
                        `Failed to fetch server details: ${response.status} ${response.statusText}`,
                    );
                }

                let serverData: ServerDetailsResponse;

                try {
                    serverData = await response.json();
                } catch (jsonError) {
                    console.error('Failed to parse server details JSON:', jsonError);
                    return;
                }

                const iconVersion = serverData.Data.iconVersion;
                const hostName = serverData.Data.hostname;
                const projectName = serverData.Data.vars.sv_projectName;

                setName(projectName ?? hostName);

                if (iconVersion) {
                    setIconUrl(
                        `https://servers-live.fivem.net/servers/icon/${id}/${iconVersion}.png`,
                    );
                }
            } catch (error) {
                console.error('Error fetching server details:', error);
            }
        },
    });

    return <context.Provider value={{ name, iconUrl }}>{children}</context.Provider>;
};
