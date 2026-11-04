import { defineConfig, minimal2023Preset } from '@vite-pwa/assets-generator/config'

// Generates the PWA icons in /public from public/logo.svg.
// Run `npm run generate-pwa-assets` after changing the logo.
export default defineConfig({
  preset: {
    ...minimal2023Preset,
    maskable: { ...minimal2023Preset.maskable, resizeOptions: { background: '#0E7C5A' } },
    apple: { ...minimal2023Preset.apple, resizeOptions: { background: '#0E7C5A' } },
  },
  images: ['public/logo.svg'],
})
