import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'node:path';

// https://vite.dev/config/
export default defineConfig({
    plugins: [
        react()
    ],
    base: './',
    build: {
        chunkSizeWarningLimit: 1000
    },
    resolve: {
        alias: {
            '@': resolve(__dirname, './src')
        }
    }
})
