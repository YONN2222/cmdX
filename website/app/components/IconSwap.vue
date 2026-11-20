<script setup lang="ts">
defineProps<{ from: string, to: string }>()
</script>

<template>
  <span class="relative grid size-[1.15em] place-items-center" aria-hidden="true">
    <UIcon :name="from" class="swap-out absolute size-full" />
    <UIcon :name="to" class="swap-in absolute size-full" />
  </span>
</template>

<style scoped>
.swap-out,
.swap-in {
  transition: transform 0.3s cubic-bezier(0.34, 1.2, 0.64, 1), opacity 0.2s ease, filter 0.3s ease;
}

.swap-in {
  opacity: 0;
  filter: blur(4px);
  transform: translateY(-120%) scaleY(0.6);
}

.group:hover .swap-out {
  opacity: 0;
  filter: blur(4px);
  transform: translateY(120%) scaleY(0.6);
}

.group:hover .swap-in {
  opacity: 1;
  filter: blur(0);
  transform: translateY(0) scaleY(1);
}
</style>
