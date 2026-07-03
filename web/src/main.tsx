import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles/global.css';

if (import.meta.env.DEV) {
  // Preview data so `npm run dev` renders the UI outside of FiveM.
  void import('./dev');
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
