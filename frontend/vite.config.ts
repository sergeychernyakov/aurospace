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
      // API requests — bypass HTML navigation to let React Router handle it
      '/orders': {
        target: 'http://localhost:3000',
        bypass(req) {
          if (req.headers.accept?.includes('text/html')) {
            return req.url;
          }
        },
      },
      '/accounts': {
        target: 'http://localhost:3000',
        bypass(req) {
          if (req.headers.accept?.includes('text/html')) {
            return req.url;
          }
        },
      },
      // Admin — use /a/ with trailing slash to avoid matching /account
      '/a/': 'http://localhost:3000',
      // Always proxy to Rails
      '/webhooks': 'http://localhost:3000',
      '/api-docs': 'http://localhost:3000',
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
