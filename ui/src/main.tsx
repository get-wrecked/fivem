import type React from 'react';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import { Container } from './components/container';
import { ServerDetails } from './components/server-details';
import Providers from './providers';

export const App: React.FC = () => {
    return (
        <Container>
            <ServerDetails />
        </Container>
    );
};

const rootElement = document.getElementById('root');

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
