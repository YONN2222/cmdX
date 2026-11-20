<script setup lang="ts">
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import KeyCap from '~/components/keyboard/KeyCap.vue'
import FinderWindow, { type DemoFile } from './FinderWindow.vue'
import MacWallpaper from './MacWallpaper.vue'

type Folder = 'Downloads' | 'Projects'

const initialFolders: Record<Folder, DemoFile[]> = {
  Downloads: [
    { name: 'Invoice.pdf', kind: 'pdf' },
    { name: 'Holiday', kind: 'folder' },
    { name: 'Logo.png', kind: 'image' },
    { name: 'Setup.dmg', kind: 'dmg' }
  ],
  Projects: [
    { name: 'Website', kind: 'folder' },
    { name: 'README.md', kind: 'markdown' }
  ]
}

const folders = ref({ ...initialFolders })
const focused = ref<Folder>('Downloads')
const selected = ref<string[]>([])
const clipboard = ref<{ from: Folder, names: string[] } | null>(null)
const message = ref('Click a file, then press Command-X')
const pressedKeys = ref<string[]>([])

const umami = useUmami()
const { playClick, playCut, playPaste } = useSounds()

function flashKeys(keys: string[]) {
  pressedKeys.value = keys
  setTimeout(() => (pressedKeys.value = []), 180)
}

function focusFolder(folder: Folder) {
  if (folder !== focused.value) selected.value = []
  focused.value = folder
}

function toggleFile(folder: Folder, name: string) {
  playClick()
  focusFolder(folder)
  selected.value = selected.value.includes(name)
    ? selected.value.filter(item => item !== name)
    : [...selected.value, name]
}

function cut() {
  flashKeys(['command', 'X'])
  if (selected.value.length === 0) {
    playClick()
    message.value = 'Select a file first'
    return
  }
  playCut()
  clipboard.value = { from: focused.value, names: selected.value }
  message.value = 'Cut. Now click the other window and press Command-V'
  umami.track('demo-cut')
}

function paste() {
  flashKeys(['command', 'V'])
  const cutFiles = clipboard.value
  if (!cutFiles) {
    playClick()
    message.value = 'Nothing cut yet. Press Command-X first'
    return
  }
  if (cutFiles.from === focused.value) {
    playClick()
    message.value = 'Click the other window, then paste'
    return
  }
  playPaste()
  const moving = folders.value[cutFiles.from].filter(file => cutFiles.names.includes(file.name))
  folders.value = {
    ...folders.value,
    [cutFiles.from]: folders.value[cutFiles.from].filter(file => !cutFiles.names.includes(file.name)),
    [focused.value]: [...folders.value[focused.value], ...moving]
  }
  message.value = `Moved to ${focused.value}. That's cmdX.`
  clipboard.value = null
  selected.value = []
  umami.track('demo-paste')
}

function reset() {
  playClick()
  umami.track('demo-reset')
  folders.value = { ...initialFolders }
  clipboard.value = null
  selected.value = []
  focused.value = 'Downloads'
  message.value = 'Click a file, then press Command-X'
}

const demoKeys = [
  { id: 'command', icon: 'i-lucide-command', caption: 'command', ariaLabel: 'Command key' },
  { id: 'X', label: 'X', caption: 'cut', ariaLabel: 'Cut selected files', action: cut },
  { id: 'V', label: 'V', caption: 'paste', ariaLabel: 'Paste into the active window', action: paste }
]

function onKeydown(event: KeyboardEvent) {
  if (!event.metaKey && !event.ctrlKey) return
  const key = event.key.toLowerCase()
  if (key === 'x') {
    event.preventDefault()
    cut()
  }
  else if (key === 'v') {
    event.preventDefault()
    paste()
  }
}

const stageRef = ref<HTMLElement>()
let context: gsap.Context | undefined

onMounted(() => {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  gsap.registerPlugin(ScrollTrigger)
  context = gsap.context(() => {
    gsap.fromTo('.macbook-lid',
      { rotateX: -55 },
      { rotateX: 0, ease: 'none', scrollTrigger: { trigger: stageRef.value, start: 'top 90%', end: 'top 20%', scrub: 0.6 } }
    )
    gsap.fromTo('.macos-wallpaper',
      { yPercent: 4 },
      { yPercent: -4, ease: 'none', scrollTrigger: { trigger: stageRef.value, start: 'top bottom', end: 'bottom top', scrub: true } }
    )
  }, stageRef.value)
})

onBeforeUnmount(() => context?.revert())
</script>

<template>
  <section id="demo" ref="stageRef" class="scroll-mt-24 px-4 pt-6 pb-24" aria-labelledby="demo-heading">
    <h2 id="demo-heading" class="sr-only">
      Try cmdX right here
    </h2>

    <div class="enter mx-auto max-w-5xl [--enter-delay:550ms] [perspective:2000px]" @keydown="onKeydown">
      <div class="macbook-lid origin-bottom rounded-t-[22px] bg-[#0d0d0f] p-[1.1%] pb-[1.6%] shadow-[0_0_0_1.5px_#3a3a3e,0_50px_90px_-40px_rgb(26_23_18/0.7)]">
        <div
          class="macos-screen relative overflow-hidden rounded-t-[12px] outline-none sm:aspect-[16/10]"
          tabindex="0"
          aria-label="Interactive cmdX demo. Select files, press Command-X, click the other window and press Command-V."
        >
          <MacWallpaper class="macos-wallpaper absolute inset-x-0 -top-[6%] h-[112%] w-full" />

          <div class="absolute top-0 left-1/2 z-30 h-[3.2%] min-h-3 w-[13%] -translate-x-1/2 rounded-b-[8px] bg-[#0d0d0f]" aria-hidden="true" />

          <div class="relative z-20 flex h-6 items-center justify-between bg-white/30 px-3 text-[11px] text-[#1d1d1f] backdrop-blur-xl">
            <span class="flex items-center gap-3.5">
              <UIcon name="i-simple-icons-apple" class="size-3" />
              <span class="font-bold">Finder</span>
              <span class="hidden sm:inline">File</span>
              <span class="hidden sm:inline">Edit</span>
              <span class="hidden sm:inline">View</span>
              <span class="hidden md:inline">Go</span>
              <span class="hidden md:inline">Window</span>
              <span class="hidden md:inline">Help</span>
            </span>
            <span class="flex items-center gap-3">
              <img src="/cmdX.png" alt="" width="14" height="14" class="size-3.5 rounded-[3px]">
              <UIcon name="i-lucide-battery-full" class="hidden size-4 sm:block" />
              <UIcon name="i-lucide-wifi" class="hidden size-3.5 sm:block" />
              <UIcon name="i-lucide-search" class="size-3" />
              <span class="font-medium">Mon 9:41</span>
            </span>
          </div>

          <div class="relative z-10 flex flex-col gap-4 p-4 sm:block sm:h-[calc(100%-1.5rem)] sm:p-0">
            <FinderWindow
              title="Downloads"
              :files="folders.Downloads"
              :selected="focused === 'Downloads' ? selected : []"
              :cut="clipboard?.from === 'Downloads' ? clipboard.names : []"
              :focused="focused === 'Downloads'"
              class="sm:absolute sm:top-[7%] sm:left-[5%] sm:w-[56%]"
              :class="focused === 'Downloads' ? 'z-20' : 'z-10'"
              @focus="focusFolder('Downloads')"
              @toggle="name => toggleFile('Downloads', name)"
            />
            <FinderWindow
              title="Projects"
              :files="folders.Projects"
              :selected="focused === 'Projects' ? selected : []"
              :cut="clipboard?.from === 'Projects' ? clipboard.names : []"
              :focused="focused === 'Projects'"
              class="sm:absolute sm:top-[30%] sm:right-[5%] sm:w-[50%]"
              :class="focused === 'Projects' ? 'z-20' : 'z-10'"
              @focus="focusFolder('Projects')"
              @toggle="name => toggleFile('Projects', name)"
            />
          </div>

          <p class="absolute bottom-[4%] left-1/2 z-30 hidden -translate-x-1/2 items-center gap-2 rounded-full bg-[#1d1d1f]/75 px-4 py-1.5 text-[11px] whitespace-nowrap text-white backdrop-blur-xl sm:flex" aria-live="polite">
            <img src="/cmdX.png" alt="" width="14" height="14" class="size-3.5 rounded-[3px]">
            {{ message }}
          </p>
        </div>
      </div>

      <div class="relative mx-[-4%] h-[14px] rounded-b-[14px] bg-[linear-gradient(to_bottom,#e6e6e9,#c4c4c9_55%,#9d9da3)] shadow-[0_18px_30px_-12px_rgb(26_23_18/0.55)] sm:h-[18px]" aria-hidden="true">
        <div class="mx-auto h-[45%] w-[14%] rounded-b-[8px] bg-[linear-gradient(to_bottom,#b9b9be,#d2d2d6)]" />
      </div>

      <div class="mt-12 flex flex-col items-center gap-6">
        <p class="text-center text-muted sm:hidden" aria-live="polite">
          {{ message }}
        </p>
        <div class="flex items-start gap-5">
          <div v-for="key in demoKeys" :key="key.id" class="flex w-20 flex-col items-center gap-2.5">
            <button
              type="button"
              class="size-16 text-[2.2rem] sm:size-[4.5rem] sm:text-[2.5rem]"
              :class="key.action ? 'cursor-pointer' : 'cursor-default'"
              :aria-label="key.ariaLabel"
              :disabled="!key.action"
              @click="key.action?.()"
            >
              <KeyCap
                :icon="key.icon"
                :label="key.label"
                :highlighted="Boolean(key.action)"
                :pressed="pressedKeys.includes(key.id)"
              />
            </button>
            <span class="font-mono text-xs text-dimmed">{{ key.caption }}</span>
          </div>
        </div>
        <p class="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-center text-muted">
          <span>Select a file, cut it, click the other window, paste.</span>
          <button type="button" class="inline-flex items-center gap-1 text-sm font-semibold text-highlighted hover:text-primary-600" @click="reset">
            <UIcon name="i-lucide-rotate-ccw" class="size-3.5" />
            Start over
          </button>
        </p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.macos-screen {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Geist", sans-serif;
}
</style>
