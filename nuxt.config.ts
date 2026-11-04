import tailwindcss from '@tailwindcss/vite'

const brandColor = '#0E7C5A'

// Pages that depend on the signed-in user or the local cart are rendered in the
// browser only. Catalog pages stay server-rendered for SEO.
const clientOnlyPages = ['/cart', '/checkout', '/login', '/account/**', '/orders/**', '/payment/**']
const clientOnlyRules = Object.fromEntries(
  clientOnlyPages.flatMap((path) => [[path, { ssr: false }], [`/en${path}`, { ssr: false }]]),
)

export default defineNuxtConfig({
  compatibilityDate: '2026-10-01',
  devtools: { enabled: false },

  modules: ['@nuxtjs/i18n', '@pinia/nuxt', '@vite-pwa/nuxt'],

  css: ['~/assets/css/main.css'],
  vite: { plugins: [tailwindcss()] },

  app: {
    head: {
      viewport: 'width=device-width, initial-scale=1, viewport-fit=cover',
      meta: [
        { name: 'theme-color', content: brandColor },
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'default' },
        { name: 'format-detection', content: 'telephone=no' },
      ],
      link: [
        { rel: 'icon', href: '/favicon.ico', sizes: '48x48' },
        { rel: 'icon', href: '/logo.svg', type: 'image/svg+xml', sizes: 'any' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon-180x180.png' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap',
        },
      ],
    },
  },

  runtimeConfig: {
    // Serve the built-in mock API under /api/v1. Set NUXT_MOCK_API=false once
    // the Django backend is live and NUXT_PUBLIC_API_BASE points to it.
    mockApi: true,
    public: {
      apiBase: '/api/v1',
      siteUrl: 'http://localhost:3000',
    },
  },

  routeRules: {
    ...clientOnlyRules,
  },

  i18n: {
    defaultLocale: 'ar',
    strategy: 'prefix_except_default',
    baseUrl: process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:3000',
    locales: [
      { code: 'ar', language: 'ar-EG', name: 'العربية', dir: 'rtl', file: 'ar.json' },
      { code: 'en', language: 'en-US', name: 'English', dir: 'ltr', file: 'en.json' },
    ],
    detectBrowserLanguage: {
      useCookie: true,
      cookieKey: 'rk_lang',
      redirectOn: 'root',
    },
  },

  pwa: {
    registerType: 'prompt',
    manifest: {
      id: '/',
      name: 'Rocket Market — روكت ماركت',
      short_name: 'Rocket',
      description: 'سوبر ماركت روكت أونلاين: خضار وفاكهة وبقالة لحد باب البيت.',
      lang: 'ar',
      dir: 'rtl',
      start_url: '/?source=pwa',
      scope: '/',
      display: 'standalone',
      orientation: 'portrait',
      theme_color: brandColor,
      background_color: '#F5F6F4',
      categories: ['shopping', 'food'],
      icons: [
        { src: 'pwa-64x64.png', sizes: '64x64', type: 'image/png' },
        { src: 'pwa-192x192.png', sizes: '192x192', type: 'image/png' },
        { src: 'pwa-512x512.png', sizes: '512x512', type: 'image/png' },
        { src: 'maskable-icon-512x512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
      ],
      shortcuts: [
        { name: 'السلة', short_name: 'السلة', url: '/cart', icons: [{ src: 'pwa-192x192.png', sizes: '192x192' }] },
        { name: 'طلباتي', short_name: 'طلباتي', url: '/orders', icons: [{ src: 'pwa-192x192.png', sizes: '192x192' }] },
      ],
    },
    workbox: {
      // This is an SSR app, so we must not answer every navigation with one
      // cached HTML shell. Pages go network-first and fall back to offline.html.
      navigateFallback: null,
      globPatterns: ['**/*.{js,css,html,svg,png,ico,woff2}'],
      // Keep the precache URLs as-is (offline.html stays offline.html).
      manifestTransforms: [],
      cleanupOutdatedCaches: true,
      runtimeCaching: [
        {
          urlPattern: ({ request }) => request.mode === 'navigate',
          handler: 'NetworkFirst',
          options: {
            cacheName: 'rk-pages',
            networkTimeoutSeconds: 4,
            expiration: { maxEntries: 60, maxAgeSeconds: 60 * 60 * 24 * 7 },
            precacheFallback: { fallbackURL: '/offline.html' },
          },
        },
        {
          // Translation bundles (hashed per build), needed to render any page offline.
          urlPattern: ({ url }) => url.pathname.startsWith('/_i18n/'),
          handler: 'CacheFirst',
          options: {
            cacheName: 'rk-i18n',
            expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 30 },
            cacheableResponse: { statuses: [200] },
          },
        },
        {
          // Catalog reads: show cached data instantly, refresh in the background.
          urlPattern: ({ url, request }) =>
            request.method === 'GET' && /\/api\/v1\/(home|categories|products|search)/.test(url.pathname),
          handler: 'StaleWhileRevalidate',
          options: {
            cacheName: 'rk-catalog-api',
            expiration: { maxEntries: 300, maxAgeSeconds: 60 * 60 * 24 },
            cacheableResponse: { statuses: [200] },
          },
        },
        {
          urlPattern: ({ url, request }) => request.method === 'GET' && /\/api\/v1\/delivery\//.test(url.pathname),
          handler: 'NetworkFirst',
          options: { cacheName: 'rk-delivery-api', networkTimeoutSeconds: 4 },
        },
        {
          urlPattern: ({ request }) => request.destination === 'image',
          handler: 'CacheFirst',
          options: {
            cacheName: 'rk-images',
            expiration: { maxEntries: 400, maxAgeSeconds: 60 * 60 * 24 * 30 },
            cacheableResponse: { statuses: [0, 200] },
          },
        },
        {
          urlPattern: /^https:\/\/fonts\.(?:googleapis|gstatic)\.com\/.*/i,
          handler: 'CacheFirst',
          options: {
            cacheName: 'rk-fonts',
            expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 365 },
            cacheableResponse: { statuses: [0, 200] },
          },
        },
      ],
    },
    client: {
      installPrompt: 'rk_install_dismissed',
      periodicSyncForUpdates: 60 * 60,
    },
    devOptions: {
      enabled: false,
      type: 'module',
    },
  },
})
