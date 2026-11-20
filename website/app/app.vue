<script setup lang="ts">
useSeoMeta({
  ogSiteName: 'cmdX',
  ogType: 'website',
  ogImage: `${SITE_URL}/og.png`,
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageAlt: 'cmdX: Cut. Paste. Finally in macOS Finder.',
  twitterCard: 'summary_large_image',
  twitterImage: `${SITE_URL}/og.png`,
  themeColor: '#f7f7f4'
})
</script>

<template>
  <UApp>
    <NuxtRouteAnnouncer />
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
