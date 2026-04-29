import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue2'
import path from 'path'
import EnvironmentPlugin from 'vite-plugin-environment'
import sitemap from './src/sitemap'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  const appTitle = env.APP_TITLE || 'Antarctic Place Names'

  return {
    plugins: [
      EnvironmentPlugin({ BUILD: 'web' }), // Only needed for Vuelidate compatibility, can be removed when Vuelidate is upgraded.
      vue(),
      {
        ...sitemap(),
        apply: 'build',
      },
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
      'import.meta.env.APP_TITLE': JSON.stringify(mode === 'production' ? appTitle : `[${mode.toUpperCase()}] ${appTitle}`)
    }
  }
})