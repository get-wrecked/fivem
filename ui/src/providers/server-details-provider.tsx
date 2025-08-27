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
    const [name, _setName] = useState<string>(initialName);
    const [iconUrl, _setIconUrl] = useState<string>(initialIconUrl);

    return <context.Provider value={{ name, iconUrl }}>{children}</context.Provider>;
};
