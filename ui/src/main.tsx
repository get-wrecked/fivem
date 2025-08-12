import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css';
import App from './App'
import { NuiProvider, NuiVisibilityProvider } from "@tsfx/hooks";

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <NuiProvider>
    <NuiVisibilityProvider>
      <App />
    </NuiVisibilityProvider>
    </NuiProvider>
    </StrictMode>,
);
