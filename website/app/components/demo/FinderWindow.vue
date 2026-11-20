<script setup lang="ts">
import MacFileIcon, { type MacFileKind } from './MacFileIcon.vue'

export interface DemoFile {
  name: string
  kind: MacFileKind
}

defineProps<{
  title: string
  files: DemoFile[]
  selected: string[]
  cut: string[]
  focused: boolean
}>()

const emit = defineEmits<{
  focus: []
  toggle: [name: string]
}>()

const favorites = [
  { name: 'AirDrop', icon: 'i-lucide-radio' },
  { name: 'Recents', icon: 'i-lucide-clock' },
  { name: 'Applications', icon: 'i-lucide-layout-grid' },
  { name: 'Desktop', icon: 'i-lucide-monitor' },
  { name: 'Downloads', icon: 'i-lucide-circle-arrow-down' },
  { name: 'Projects', icon: 'i-lucide-folder' }
]
</script>

<template>
  <div
    class="mac-window flex overflow-hidden rounded-[10px] bg-white text-[11px] transition-shadow duration-200"
    :class="focused ? 'shadow-[0_22px_50px_-10px_rgb(0_0_0/0.45),0_0_0_0.5px_rgb(0_0_0/0.25)]' : 'shadow-[0_12px_30px_-10px_rgb(0_0_0/0.3),0_0_0_0.5px_rgb(0_0_0/0.18)]'"
    @pointerdown="emit('focus')"
  >
    <aside class="hidden w-[30%] shrink-0 flex-col bg-[#ecebee]/85 px-2 pt-2.5 pb-3 backdrop-blur-xl sm:flex">
      <div class="flex gap-[6px] px-1.5 pb-3">
        <span class="size-[10px] rounded-full" :class="focused ? 'bg-[#ff5f57]' : 'bg-[#d6d5d8]'" />
        <span class="size-[10px] rounded-full" :class="focused ? 'bg-[#febc2e]' : 'bg-[#d6d5d8]'" />
        <span class="size-[10px] rounded-full" :class="focused ? 'bg-[#28c840]' : 'bg-[#d6d5d8]'" />
      </div>
      <p class="px-2 pb-1 text-[9.5px] font-semibold text-[#8e8e93]">
        Favorites
      </p>
      <span
        v-for="item in favorites"
        :key="item.name"
        class="flex items-center gap-1.5 rounded-[5px] px-2 py-[3px] text-[#1d1d1f]"
        :class="item.name === title && 'bg-black/[0.08]'"
      >
        <UIcon :name="item.icon" class="size-3.5 text-[#0a7cff]" />
        {{ item.name }}
      </span>
      <p class="px-2 pt-2.5 pb-1 text-[9.5px] font-semibold text-[#8e8e93]">
        Locations
      </p>
      <span class="flex items-center gap-1.5 px-2 py-[3px] text-[#1d1d1f]">
        <UIcon name="i-lucide-hard-drive" class="size-3.5 text-[#8e8e93]" />
        Macintosh HD
      </span>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <div class="flex h-10 items-center gap-2 border-b border-black/[0.07] px-3 text-[#1d1d1f]">
        <div class="flex gap-[6px] sm:hidden">
          <span class="size-[10px] rounded-full bg-[#ff5f57]" />
          <span class="size-[10px] rounded-full bg-[#febc2e]" />
          <span class="size-[10px] rounded-full bg-[#28c840]" />
        </div>
        <UIcon name="i-lucide-chevron-left" class="size-4 text-[#1d1d1f]/70" />
        <UIcon name="i-lucide-chevron-right" class="size-4 text-[#1d1d1f]/25" />
        <span class="ml-1 truncate text-[12.5px] font-bold">{{ title }}</span>
        <span class="ml-auto flex items-center gap-3 text-[#1d1d1f]/60">
          <UIcon name="i-lucide-layout-grid" class="size-3.5" />
          <UIcon name="i-lucide-share" class="hidden size-3.5 md:block" />
          <UIcon name="i-lucide-search" class="size-3.5" />
        </span>
      </div>

      <div class="grid min-h-40 flex-1 grid-cols-3 content-start gap-x-1 gap-y-3 p-3 lg:grid-cols-4">
        <TransitionGroup name="file">
          <button
            v-for="file in files"
            :key="file.name"
            type="button"
            class="group flex flex-col items-center gap-1 outline-none transition-opacity duration-200"
            :class="cut.includes(file.name) && 'opacity-40'"
            :aria-pressed="selected.includes(file.name)"
            @click="emit('toggle', file.name)"
          >
            <span
              class="grid size-[54px] place-items-center rounded-[6px] p-1.5"
              :class="selected.includes(file.name) ? 'bg-black/[0.09]' : 'group-hover:bg-black/[0.04]'"
            >
              <MacFileIcon :kind="file.kind" class="size-full" />
            </span>
            <span
              class="max-w-full truncate rounded-[4px] px-1.5 py-px text-[10.5px]"
              :class="selected.includes(file.name) ? 'bg-[#0a64d2] text-white' : 'text-[#1d1d1f]'"
            >{{ file.name }}</span>
          </button>
        </TransitionGroup>
      </div>

      <div class="flex h-6 items-center justify-center border-t border-black/[0.07] bg-[#f6f6f7] text-[9.5px] text-[#8e8e93]">
        {{ files.length }} items
      </div>
    </div>
  </div>
</template>

<style scoped>
.mac-window {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Geist", sans-serif;
}

.file-enter-active,
.file-leave-active {
  transition: opacity 0.3s ease, transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.file-enter-from,
.file-leave-to {
  opacity: 0;
  transform: scale(0.6);
}
</style>
