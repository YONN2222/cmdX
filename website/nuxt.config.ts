export default defineNuxtConfig({
  modules: ['@nuxt/ui', 'nuxt-umami-plugin'],
  css: ['~/assets/css/main.css'],
  ui: { colorMode: false },
  fonts: {
    families: [
      { name: 'Nunito', provider: 'google', weights: [700, 800, 900] },
      { name: 'Geist', provider: 'google', weights: [400, 500, 600] },
      { name: 'JetBrains Mono', provider: 'google', weights: [400, 600, 700] }
    ]
  },
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'manifest', href: '/site.webmanifest' }
      ]
    }
  },

  runtimeConfig: {
    githubToken: ''
  },

  routeRules: {
    '/': { prerender: true },
    '/changelog': { prerender: true },
    '/privacy': { prerender: true }
  },

  umami: {
    websiteId: '3555f6e5-8996-4a5f-a03c-40789b9f4b3b',
    host: 'https://umami.yonn2222.com',
    domains: ['cmdx.yonn.online'],
    replay: true,
    performance: true,
    errors: true
  },

  nitro: {
    preset: 'cloudflare_module',
    prerender: { autoSubfolderIndex: false }
  }
})
