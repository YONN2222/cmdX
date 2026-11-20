<script setup lang="ts">
defineProps<{ letter: string }>()
</script>

<template>
  <span class="inline-flex items-center gap-0.5 align-middle">
    <MacKey name="command" />
    <MacKey :name="letter" />
  </span>
</template>
