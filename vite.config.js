import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue2'
import path from 'path'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  const appTitle = env.APP_TITLE || 'SCAR Composite Gazetteer of Antarctica (CGA)'

  return {
    plugins: [
      vue()
    ],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      }
    },
    server: {
      proxy: {
        "/api": {
          target: "http://localhost:3000",
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
        "/user/api": {
          target: "https://data.aad.gov.au",
          changeOrigin: true
        },
      },
    },
    define: {
      'import.meta.env.APP_TITLE': JSON.stringify(env.PROD ? appTitle : `[${mode.toUpperCase()}] ${appTitle}`)
    }
  }
})