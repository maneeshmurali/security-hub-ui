import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    host: true,
    proxy: {
      '/api': 'http://localhost:8000',
      '/static': 'http://localhost:8000'
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false
  }
});