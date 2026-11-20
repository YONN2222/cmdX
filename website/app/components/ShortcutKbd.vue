<script setup lang="ts">
defineProps<{ letter: string }>()
</script>

<template>
  <span class="inline-flex items-center gap-0.5 align-middle">
    <UKbd><UIcon name="i-lucide-command" class="size-3" /></UKbd>
    <UKbd :value="letter" />
  </span>
</template>
