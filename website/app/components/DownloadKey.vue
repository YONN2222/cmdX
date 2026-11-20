<script setup lang="ts">
defineProps<{ location: string }>()

const { data: stats } = await useGithubStats()
const { onDownload } = useDownload()
</script>

<template>
  <a href="/download" class="btn-key group" @click="onDownload(location, stats?.version)">
    <IconSwap from="i-simple-icons-apple" to="i-lucide-arrow-down-to-line" />
    Download for Mac
  </a>
</template>
