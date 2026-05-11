import { defineConfig } from 'vite'
import { devtools } from '@tanstack/devtools-vite'

import { tanstackStart } from '@tanstack/react-start/plugin/vite'

import viteReact from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

const config = defineConfig({
  // Portless passes a dynamic port and an IPv4 host in $PORT and $HOST.
  server: {
    port: Number(process.env.PORT) || 3000,
    host: process.env.HOST || '127.0.0.1',
  },
  resolve: { tsconfigPaths: true },
  plugins: [
    devtools(),
    tailwindcss(),
    // Prerendered to static files for Cloudflare Pages; nothing renders per request.
    tanstackStart({ prerender: { enabled: true, crawlLinks: true } }),
    viteReact(),
  ],
})

export default config
