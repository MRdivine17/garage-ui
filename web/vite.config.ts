import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// base: './' -> relative asset paths, required for FiveM NUI (nui://) loading.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsDir: 'assets',
    chunkSizeWarningLimit: 1500,
  },
});
