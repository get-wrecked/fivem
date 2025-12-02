/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/main.tsx
  =====================
  Description:
    Root application component for the UI
  ---
  Exports & Exported Components:
    - App : The root application component
  ---
  Globals:
    None
*/

import { useNuiEvent } from '@tsfx/hooks';
import i18n from 'i18next';
import Backend from 'i18next-http-backend';
import type React from 'react';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { initReactI18next } from 'react-i18next';
import { AutoClipping } from './components/auto-clipping';
import { ClipLength } from './components/clip-length';
import { Container } from './components/container';
import { ServerDetails } from './components/server-details';
import Providers from './providers';

import './index.css';
import '@/superSoaker/capture'; //=-- This import boots the SuperSoaker NUI capture as a side-effect

i18n.use(Backend)
    .use(initReactI18next)
    .init({
        fallbackLng: 'en',
        interpolation: { escapeValue: false },
        backend: {
            loadPath: './locales/{{lng}}/{{ns}}.json',
        },
    });

/**
 * Root application component.
 *
 * Renders the primary container and child panels for the Medal auto-clipping in-game UI.
 */
export const App: React.FC = () => {
    useNuiEvent<string>('ui:locale', { handler: (locale) => i18n.changeLanguage(locale) });

    return (
        <div className='w-screen h-screen overflow-hidden relative select-none'>
            <Container>
                <ServerDetails />
                <AutoClipping />
                <ClipLength />
            </Container>
        </div>
    );
};

const rootElement = document.getElementById('root');

//=-- Bootstrap the React root, ONCE
if (!rootElement.innerHTML) {
    const root = createRoot(rootElement);

    root.render(
        <StrictMode>
            <Providers>
                <App />
            </Providers>
        </StrictMode>,
    );
}
