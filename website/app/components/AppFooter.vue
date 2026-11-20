<script setup lang="ts">
interface DockItem {
  label: string
  to: string
  icon?: string
  tile?: string
}

const items: DockItem[] = [
  { label: 'cmdX', to: '/' },
  { label: 'GitHub', to: LINKS.repo, icon: 'i-simple-icons-github', tile: 'bg-[#232326] text-white' },
  { label: 'Changelog', to: '/changelog', icon: 'i-lucide-scroll-text', tile: 'bg-[image:var(--icon-gradient)] text-[#2c2c2e]' },
  { label: 'Issues', to: LINKS.issues, icon: 'i-lucide-bug', tile: 'bg-white text-[#2c2c2e]' },
  { label: 'License', to: LINKS.license, icon: 'i-lucide-scale', tile: 'bg-[#e9e7f8] text-[#463f7c]' }
]

const year = new Date().getFullYear()
const { playClick } = useSounds()
</script>

<template>
  <footer class="pt-20 pb-10">
    <UContainer class="flex flex-col items-center">
      <nav aria-label="Project links">
        <ul class="flex items-end gap-1.5 rounded-[1.15rem] border border-white/80 bg-white/60 px-2 pt-2 pb-1 shadow-[0_14px_30px_-18px_rgb(29_29_31/0.35),0_0_0_1px_rgb(29_29_31/0.06)] backdrop-blur-xl">
          <li v-for="item in items" :key="item.label" class="dock-item group relative flex flex-col items-center">
            <span class="dock-label pointer-events-none absolute -top-9 rounded-md bg-[#2c2c2e]/90 px-2.5 py-1 text-xs font-semibold whitespace-nowrap text-white">
              {{ item.label }}
            </span>
            <NuxtLink
              :to="item.to"
              :target="item.to.startsWith('http') ? '_blank' : undefined"
              :aria-label="item.label"
              class="dock-icon block size-10"
              v-umami="{ name: 'dock-click', target: item.label }"
              @click="playClick"
            >
              <img v-if="!item.icon" src="/cmdX.png" alt="" width="56" height="56" class="size-full rounded-[22%] shadow-[0_4px_10px_-4px_rgb(29_29_31/0.4)]">
              <span v-else class="grid size-full place-items-center rounded-[22%] shadow-[0_4px_10px_-4px_rgb(29_29_31/0.4),inset_0_0_0_1px_rgb(29_29_31/0.06)]" :class="item.tile">
                <UIcon :name="item.icon" class="size-[45%]" />
              </span>
            </NuxtLink>
            <span class="mt-1 size-1 rounded-full" :class="item.icon ? 'bg-transparent' : 'bg-[#2c2c2e]/60'" aria-hidden="true" />
          </li>
        </ul>
      </nav>

      <p class="mt-6 text-sm text-dimmed">
        &copy; {{ year }} cmdX. Made for everyone who misses Command-X in Finder.
      </p>
      <NuxtLink to="/privacy" class="mt-2 text-sm font-medium text-dimmed underline-offset-4 hover:text-highlighted hover:underline">
        Privacy Policy
      </NuxtLink>
    </UContainer>
  </footer>
</template>

<style scoped>
.dock-icon {
  transform-origin: bottom center;
  transition: transform 0.25s cubic-bezier(0.34, 1.2, 0.64, 1);
}

.dock-item:hover .dock-icon {
  transform: translateY(-4px) scale(1.2);
}

.dock-item:hover + .dock-item .dock-icon,
.dock-item:has(+ .dock-item:hover) .dock-icon {
  transform: translateY(-1px) scale(1.07);
}

.dock-label {
  opacity: 0;
  transform: translateY(4px);
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.dock-item:hover .dock-label {
  opacity: 1;
  transform: translateY(-8px);
}

@media (prefers-reduced-motion: reduce) {
  .dock-item:hover .dock-icon,
  .dock-item:hover + .dock-item .dock-icon,
  .dock-item:has(+ .dock-item:hover) .dock-icon {
    transform: none;
  }
}
</style>
