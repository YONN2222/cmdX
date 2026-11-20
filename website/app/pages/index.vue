<script setup lang="ts">
import MacDemo from '~/components/demo/MacDemo.vue'

const { data: stats, refresh } = await useGithubStats()
onMounted(() => refresh())
useSectionTracking(['demo', 'features', 'install', 'faq'])

const title = 'cmdX: Cut & Paste Files in macOS Finder with Command-X'
const description = 'cmdX is a free, open source Mac app that makes the Command-X (Cmd+X) shortcut cut files in Finder. Cut with Cmd+X, move with Cmd+V. Apple Silicon & Intel.'

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogUrl: SITE_URL,
  twitterTitle: title,
  twitterDescription: description
})

useHead({
  link: [{ rel: 'canonical', href: `${SITE_URL}/` }],
  script: [{
    type: 'application/ld+json',
    innerHTML: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'SoftwareApplication',
      'name': 'cmdX',
      'alternateName': 'cmdX for Mac',
      'keywords': 'Command-X shortcut, Cmd+X in Finder, cut and paste files on Mac, move files in Finder, macOS Finder cut',
      'url': `${SITE_URL}/`,
      'description': description,
      'applicationCategory': 'UtilitiesApplication',
      'operatingSystem': 'macOS 14.0 or later',
      'image': `${SITE_URL}/android-chrome-512x512.png`,
      'downloadUrl': LINKS.releases,
      'softwareVersion': stats.value?.version ?? undefined,
      'license': 'https://opensource.org/licenses/MIT',
      'isAccessibleForFree': true,
      'offers': { '@type': 'Offer', 'price': '0', 'priceCurrency': 'USD' },
      'author': { '@type': 'Person', 'name': 'YONN2222', 'url': LINKS.author },
      'sameAs': [LINKS.repo]
    })
  }]
})
</script>

<template>
  <main>
    <HeroSection />
    <MacDemo />
    <FeatureIcons />
    <InstallSection />
    <FaqSection />
  </main>
</template>
