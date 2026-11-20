<script setup lang="ts">
const links = [
  { label: 'Try it', to: '/#demo', icon: 'i-lucide-mouse-pointer-click' },
  { label: 'Features', to: '/#features', icon: 'i-lucide-sparkles' },
  { label: 'Changelog', to: '/changelog', icon: 'i-lucide-scroll-text' },
  { label: 'FAQ', to: '/#faq', icon: 'i-lucide-message-circle-question' }
]

const { data: stats } = await useGithubStats()
const { muted, toggleMuted } = useSounds()
const { onDownload } = useDownload()
const umami = useUmami()

function onToggleSound() {
  toggleMuted()
  umami.track('sound-toggle', { muted: muted.value })
}

const scrolled = ref(false)
function onScroll() {
  scrolled.value = window.scrollY > 32
}
onMounted(() => {
  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
})
onBeforeUnmount(() => window.removeEventListener('scroll', onScroll))
</script>

<template>
  <header
    class="sticky top-0 z-40 transition-[background-color,box-shadow] duration-300"
    :class="scrolled ? 'bg-paper/80 shadow-[0_20px_40px_-20px_rgb(29_29_31/0.18),0_0_0_1px_rgb(29_29_31/0.05)] backdrop-blur-xl' : 'bg-transparent'"
  >
    <UContainer class="flex h-20 items-center justify-between gap-4">
      <NuxtLink to="/" class="enter-logo group flex items-center gap-3" aria-label="cmdX home">
        <img
          src="/cmdX.png"
          alt=""
          width="40"
          height="40"
          class="size-10 rounded-[0.7rem] shadow-[0_2px_6px_rgb(29_29_31/0.16)] transition-transform duration-300 [transition-timing-function:cubic-bezier(0.34,1.2,0.64,1)] group-hover:-rotate-8 group-hover:scale-110"
        >
        <span class="font-display text-[1.6rem] font-black tracking-tight text-highlighted">cmdX</span>
      </NuxtLink>

      <nav class="flex items-center gap-1 sm:gap-2" aria-label="Main">
        <NuxtLink
          v-for="(link, index) in links"
          :key="link.to"
          :to="link.to"
          class="nav-item group hidden items-center gap-1.5 rounded-xl px-3 py-2 font-display text-[1.05rem] font-extrabold text-highlighted transition-colors hover:bg-paper-deep md:flex"
          :style="{ '--enter-delay': `${300 + index * 60}ms` }"
          v-umami="{ name: 'nav-click', target: link.label }"
        >
          <UIcon :name="link.icon" class="nav-icon size-[1.15rem]" />
          {{ link.label }}
        </NuxtLink>
        <a
          :href="LINKS.repo"
          target="_blank"
          rel="noopener"
          class="nav-item group hidden items-center gap-1.5 rounded-xl px-3 py-2 font-display text-[1.05rem] font-extrabold text-highlighted transition-colors hover:bg-paper-deep lg:flex"
          style="--enter-delay: 540ms"
          v-umami="{ name: 'github-click', location: 'header' }"
        >
          <UIcon name="i-simple-icons-github" class="nav-icon size-[1.1rem]" />
          GitHub
          <span v-if="stats" class="rounded-md bg-paper-deep px-1.5 py-0.5 font-mono text-xs font-semibold text-muted transition-colors group-hover:bg-white">{{ stats.stars }}</span>
        </a>
        <button
          type="button"
          class="nav-item group grid size-11 place-items-center rounded-xl text-highlighted transition-colors hover:bg-paper-deep"
          style="--enter-delay: 600ms"
          :aria-label="muted ? 'Turn sounds on' : 'Turn sounds off'"
          :aria-pressed="!muted"
          @click="onToggleSound"
        >
          <UIcon :name="muted ? 'i-lucide-volume-x' : 'i-lucide-volume-2'" class="nav-icon size-5" />
        </button>
        <a
          href="/download"
          class="nav-item group flex items-center gap-2 rounded-2xl bg-paper-deep px-5 py-3 font-display text-[1.05rem] font-extrabold text-highlighted transition-[background-color,transform] duration-200 hover:bg-[#e4e4de] active:scale-[0.96]"
          style="--enter-delay: 660ms"
          @click="onDownload('header', stats?.version)"
        >
          <IconSwap from="i-simple-icons-apple" to="i-lucide-arrow-down-to-line" />
          Download
        </a>
      </nav>
    </UContainer>
  </header>
</template>

<style scoped>
.enter-logo {
  animation: logo-rise 0.5s 0.075s ease both;
}

.nav-item {
  animation: nav-in 0.5s var(--enter-delay, 0.3s) cubic-bezier(0.34, 1.2, 0.64, 1) both;
}

.nav-icon {
  transition: transform 0.35s cubic-bezier(0.34, 1.2, 0.64, 1);
}

.group:hover .nav-icon {
  transform: translateY(-2px) rotate(-12deg) scale(1.12);
}

@keyframes logo-rise {
  from {
    opacity: 0;
    transform: translateY(16px) scale(0.75) rotate(6deg);
  }
}

@keyframes nav-in {
  from {
    opacity: 0;
    transform: translateY(-6px) scale(0.9);
  }
}

@media (prefers-reduced-motion: reduce) {
  .enter-logo,
  .nav-item {
    animation: none;
  }

  .group:hover .nav-icon {
    transform: none;
  }
}
</style>
