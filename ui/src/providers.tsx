import { NuiProvider, NuiVisibilityProvider } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import NuiHandlers from './handlers/nui-handlers';
import { ServerDetailsProvider } from './providers/server-details-provider';

/**
 * The React app's providers helper.
 *
 * Wraps the app with `NuiProvider` and `NuiVisibilityProvider`, and mounts
 * `NuiHandlers` to register all LUA/CFX to UI event listeners/handlers.
 *
 * @param props.debug - When `true`, enables debug output in the providers/hooks.
 */
const Providers: React.FC<PropsWithChildren<{ debug?: boolean }>> = ({
    children,
    debug = false,
}) => {
    return (
        <NuiProvider debug={debug}>
            <NuiVisibilityProvider debug={debug}>
                <ServerDetailsProvider>
                    {/*//=-- Registers listeners for messages from Lua/CFX */}
                    <NuiHandlers />
                    {children}
                </ServerDetailsProvider>
            </NuiVisibilityProvider>
        </NuiProvider>
    );
};

export default Providers;
