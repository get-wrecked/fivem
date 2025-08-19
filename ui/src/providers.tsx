import { NuiProvider, NuiVisibilityProvider } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import NuiHandlers from './handlers/NuiHandlers';

const Providers: React.FC<PropsWithChildren<{ debug?: boolean }>> = ({
    children,
    debug = false,
}) => {
    return (
        <NuiProvider debug={debug}>
            <NuiVisibilityProvider debug={debug}>
                {/*//=-- Registers listeners for messages from Lua/CFX */}
                <NuiHandlers />
                {children}
            </NuiVisibilityProvider>
        </NuiProvider>
    );
};

export default Providers;
