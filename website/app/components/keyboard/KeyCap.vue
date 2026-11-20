<script setup lang="ts">
defineProps<{
  label?: string
  icon?: string
  pressed?: boolean
  highlighted?: boolean
}>()
</script>

<template>
  <span
    class="key"
    :class="{ 'key-pressed': pressed, 'key-highlighted': highlighted }"
  >
    <UIcon v-if="icon" :name="icon" class="size-[0.9em]" />
    <span v-if="label">{{ label }}</span>
  </span>
</template>

<style scoped>
.key {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.25em;
  height: 100%;
  border-radius: 0.45em;
  border: 1px solid color-mix(in oklab, var(--ui-text) 10%, transparent);
  background: linear-gradient(to bottom, #ffffff, #f1f1ed);
  color: var(--ui-text-muted);
  font-family: var(--font-mono);
  font-size: 0.7em;
  box-shadow: 0 0.28em 0 #d6d6d0, 0 0.4em 0.6em rgb(29 29 31 / 0.08);
  transition: transform 0.15s ease, box-shadow 0.15s ease, background 0.2s ease, color 0.2s ease;
  user-select: none;
}

.key-highlighted {
  background: var(--icon-gradient);
  border-color: #c9c5e8;
  color: var(--color-ink);
  box-shadow: 0 0.28em 0 #bdb8dc, 0 0.5em 0.9em rgb(107 96 187 / 0.18);
}

.key-pressed {
  transform: translateY(0.22em);
  box-shadow: 0 0.06em 0 #d6d6d0;
}

.key-highlighted.key-pressed {
  box-shadow: 0 0.06em 0 #bdb8dc, 0 0.2em 0.4em rgb(107 96 187 / 0.18);
}
</style>
