import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import type React from 'react';
import { type PropsWithChildren, useCallback, useEffect, useState } from 'react';
import { type UiMode, UiModeContext, type UiModeContextValue } from '@/contexts/ui-mode-context';

export interface UiModeProviderProps {
    context?: React.Context<UiModeContextValue>;
}

export const UiModeProvider: React.FC<PropsWithChildren<UiModeProviderProps>> = ({
    children,
    context = UiModeContext,
}) => {
    const [mode, setMode] = useState<UiMode>('closed');
    const { visible, setVisible } = useNuiVisibility();

    useNuiEvent<UiMode>('ui:mode', {
        handler: (newMode) => {
            setMode(newMode);

            if (newMode === 'closed') {
                setVisible(false);
            } else {
                setVisible(true);
            }
        },
    });

    const openSlideover = useCallback(() => {
        setMode('slideover');
        setVisible(true);
    }, [setVisible]);

    const openReporting = useCallback(() => {
        setMode('reporting');
        setVisible(true);
    }, [setVisible]);

    const closeAll = useCallback(() => {
        setMode('closed');
        setVisible(false);
    }, [setVisible]);

    useEffect(() => {
        if (!visible && mode !== 'closed') {
            setMode('closed');
        }
    }, [visible, mode]);

    return (
        <context.Provider value={{ mode, setMode, openSlideover, openReporting, closeAll }}>
            {children}
        </context.Provider>
    );
};
