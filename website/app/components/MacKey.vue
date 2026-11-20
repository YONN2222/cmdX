<script setup lang="ts">
const props = defineProps<{ name: string }>()

const icons: Record<string, string> = {
  command: 'i-lucide-command',
  option: 'i-lucide-option'
}

const icon = computed(() => icons[props.name])
</script>

<template>
  <UKbd v-if="icon" :aria-label="name"><UIcon :name="icon" class="size-3" /></UKbd>
  <UKbd v-else :value="name" />
</template>
