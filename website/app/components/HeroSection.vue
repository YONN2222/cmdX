<script setup lang="ts">
import DotGrid from '~/components/bits/DotGrid.vue'
import CountUp from '~/components/bits/CountUp.vue'
import KeyCap from '~/components/keyboard/KeyCap.vue'

const { data: stats } = await useGithubStats()
const { playClick, playCut, playPaste } = useSounds()
const umami = useUmami()

const isCut = ref(false)
const pasteBounce = ref(false)
const pressedKey = ref<'command' | 'X' | null>(null)
const hint = ref('')

function flash(key: 'command' | 'X') {
  pressedKey.value = key
  setTimeout(() => (pressedKey.value = null), 160)
}

function cutWord(source: string) {
  flash('X')
  playCut()
  isCut.value = true
  hint.value = 'Now press Command-V'
  umami.track('hero-cut', { source })
}

function pasteWord(source: string) {
  if (!isCut.value) return
  flash('X')
  playPaste()
  isCut.value = false
  hint.value = ''
  pasteBounce.value = false
  requestAnimationFrame(() => (pasteBounce.value = true))
  umami.track('hero-paste', { source })
}

function pressCommand() {
  flash('command')
  playClick()
  hint.value = 'Command plus X. Try it on your keyboard.'
}

function isTyping(target: EventTarget | null) {
  return target instanceof HTMLElement && (target.isContentEditable || ['INPUT', 'TEXTAREA'].includes(target.tagName))
}

function onKeydown(event: KeyboardEvent) {
  if (event.defaultPrevented || (!event.metaKey && !event.ctrlKey) || isTyping(event.target)) return
  if (window.getSelection()?.toString()) return
  const key = event.key.toLowerCase()
  if (key === 'x') cutWord('keyboard')
  else if (key === 'v') pasteWord('keyboard')
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <section class="relative isolate overflow-hidden pt-14 pb-16 sm:pt-20">
    <ClientOnly>
      <DotGrid
        class-name="absolute inset-0 -z-10 [mask-image:linear-gradient(to_bottom,black_40%,transparent)]"
        :dot-size="3"
        :gap="26"
        base-color="#dcdcd6"
        active-color="#8177cf"
        :proximity="80"
        :strength="0.25"
        :shock-strength="1"
        :swell="0.2"
      />
    </ClientOnly>

    <UContainer class="grid items-center gap-14 lg:grid-cols-[1.4fr_1fr]">
      <div>
        <h1 class="enter font-display font-black tracking-[-0.04em] text-highlighted [--enter-delay:150ms]">
          <span class="cut-word block w-fit text-[clamp(4.5rem,12vw,8.5rem)] leading-[0.85]" :class="{ 'is-cut': isCut }">Cut.</span>
          <span class="block w-fit text-[clamp(4.5rem,12vw,8.5rem)] leading-[0.85]" :class="{ 'paste-bounce': pasteBounce }" @animationend="pasteBounce = false">Paste.</span>
          <span class="mt-5 block text-[clamp(1.8rem,3.6vw,2.8rem)] leading-tight font-extrabold tracking-[-0.02em]">
            Finally in <span class="rounded-[0.2em] bg-[image:var(--icon-gradient)] px-[0.15em] box-decoration-clone">macOS Finder</span>.
          </span>
        </h1>

        <p class="enter mt-6 max-w-[54ch] text-lg text-muted [--enter-delay:250ms] sm:text-xl">
          <strong class="font-semibold text-highlighted">cmdX</strong> gives Finder the Command-X it never had.
          Cut files with <ShortcutKbd letter="X" />, move them with <ShortcutKbd letter="V" />. Free and open source.
        </p>

        <div class="enter mt-10 flex flex-wrap items-center gap-5 [--enter-delay:350ms]">
          <DownloadKey location="hero" />
          <a
            :href="LINKS.repo"
            target="_blank"
            rel="noopener"
            class="btn-soft group"
            v-umami="{ name: 'github-click', location: 'hero' }"
          >
            <UIcon name="i-simple-icons-github" class="size-5" />
            Open source
            <span v-if="stats" class="flex items-center gap-1 rounded-lg bg-[#232326] px-2 py-1 font-mono text-xs font-semibold text-white">
              <UIcon name="i-lucide-star" class="size-3.5 transition-transform duration-500 group-hover:rotate-[144deg] group-hover:text-[#ffd34d]" />
              {{ stats.stars }}
            </span>
          </a>
        </div>

        <p class="enter mt-6 font-mono text-xs text-dimmed [--enter-delay:450ms]">
          <template v-if="stats">
            <CountUp :key="stats.downloads" :to="stats.downloads" separator="," :duration="1.4" trigger="view" class-name="font-semibold text-muted" />
            downloads<span class="sr-only"> ({{ stats.downloads }})</span> /
          </template>
          macOS 14 or later / Apple Silicon &amp; Intel
        </p>
      </div>

      <div class="hidden flex-col items-center gap-8 lg:flex">
        <div class="flex items-end justify-center gap-5 text-[clamp(2.4rem,4.6vw,4.4rem)] [perspective:900px]">
          <button
            type="button"
            class="hero-key size-[2.7em] cursor-pointer [transform:rotateX(26deg)_rotateZ(-5deg)]"
            aria-label="Command key"
            @click="pressCommand"
          >
            <KeyCap icon="i-lucide-command" :pressed="pressedKey === 'command'" class="text-[1.5em]" />
          </button>
          <button
            type="button"
            class="hero-key hero-key-late mb-[0.7em] size-[2.7em] cursor-pointer [transform:rotateX(26deg)_rotateZ(6deg)]"
            :aria-label="isCut ? 'Paste the word back' : 'Cut the word Cut'"
            @click="isCut ? pasteWord('click') : cutWord('click')"
          >
            <KeyCap :label="isCut ? 'V' : 'X'" highlighted :pressed="pressedKey === 'X'" class="text-[1.5em]" />
          </button>
        </div>
        <p class="h-5 font-mono text-xs text-dimmed" aria-live="polite">
          {{ hint || 'Go on, press it.' }}
        </p>
      </div>
    </UContainer>
  </section>
</template>

<style scoped>
.hero-key {
  animation: key-press 0.5s 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
}

.hero-key-late {
  animation-delay: 0.75s;
}

@keyframes key-press {
  0%, 100% { translate: 0 0; }
  45% { translate: 0 0.14em; }
}

.cut-word {
  transition: opacity 0.35s ease, transform 0.45s cubic-bezier(0.34, 1.4, 0.64, 1);
}

.cut-word.is-cut {
  opacity: 0.35;
  transform: translate(0.12em, -0.06em) rotate(-3deg);
}

.paste-bounce {
  animation: paste-pop 0.5s cubic-bezier(0.34, 1.4, 0.64, 1);
}

@keyframes paste-pop {
  40% { transform: translateY(-0.08em) scale(1.03); }
}

@media (prefers-reduced-motion: reduce) {
  .hero-key,
  .paste-bounce {
    animation: none;
  }

  .cut-word {
    transition: opacity 0.2s ease;
  }

  .cut-word.is-cut {
    transform: none;
  }
}
</style>
