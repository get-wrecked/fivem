import { useContext } from 'react';
import { UiModeContext } from '@/contexts/ui-mode-context';

export const useUiMode = () => {
    const context = useContext(UiModeContext);

    if (!context) {
        throw new Error('useUiMode must be used within a UiModeProvider');
    }

    return context;
};
