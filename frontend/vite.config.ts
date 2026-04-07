// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/orders': 'http://localhost:3000',
      '/accounts': 'http://localhost:3000',
      '/webhooks': 'http://localhost:3000',
      '/api-docs': 'http://localhost:3000',
      '/a': 'http://localhost:3000',
      '/assets': 'http://localhost:3000',
      '/up': 'http://localhost:3000',
      '/health': 'http://localhost:3000',
    },
  },
  build: {
    outDir: '../public/frontend',
    emptyOutDir: true,
  },
});
