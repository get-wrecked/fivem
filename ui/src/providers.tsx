import { NuiProvider, NuiVisibilityProvider } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';

const Providers: React.FC<PropsWithChildren<{ debug?: boolean }>> = ({
    children,
    debug = false,
}) => {
    return (
        <NuiProvider debug={debug}>
            <NuiVisibilityProvider debug={debug}>{children}</NuiVisibilityProvider>
        </NuiProvider>
    );
};

export default Providers;
