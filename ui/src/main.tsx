import type React from 'react';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import Providers from './providers';

const App: React.FC = () => {
    return <span>TODO</span>;
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
