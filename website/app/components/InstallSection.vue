<script setup lang="ts">
const commands = [
  'brew tap YONN2222/cmdx https://github.com/YONN2222/cmdX',
  'brew install cmdx'
]

const umami = useUmami()
const { playClick } = useSounds()
const { notify } = useMacNotification()

async function copyCommands() {
  playClick()
  try {
    await navigator.clipboard.writeText(commands.join(' && '))
    notify({ title: 'Copied to clipboard', body: 'Paste it into Terminal to install cmdX with Homebrew.' })
    umami.track('copy-brew')
  }
  catch {
    notify({ title: 'Could not copy', body: 'Please select the commands and copy them manually.' })
  }
}
</script>

<template>
  <section id="install" class="scroll-mt-24 pb-28">
    <UContainer class="flex flex-col items-center text-center">
      <DownloadKey location="install" />
      <p class="mt-4 text-sm text-dimmed">
        macOS 14 Sonoma or later. Allow Accessibility access on first launch.
      </p>

      <div class="mt-14 w-full max-w-xl overflow-hidden rounded-xl bg-[#1f1f22] text-left shadow-[0_24px_50px_-20px_rgb(29_29_31/0.55),0_0_0_1px_rgb(0_0_0/0.4)]">
        <div class="relative flex h-9 items-center px-3.5">
          <span class="flex gap-[7px]" aria-hidden="true">
            <span class="size-3 rounded-full bg-[#ff5f57]" />
            <span class="size-3 rounded-full bg-[#febc2e]" />
            <span class="size-3 rounded-full bg-[#28c840]" />
          </span>
          <span class="absolute inset-x-0 text-center text-xs font-semibold text-white/55">Install with Homebrew</span>
          <button
            type="button"
            class="relative ml-auto flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-semibold text-white/70 transition-colors hover:bg-white/10 hover:text-white"
            @click="copyCommands"
          >
            <UIcon name="i-lucide-copy" class="size-3.5" />
            Copy
          </button>
        </div>
        <pre class="border-t border-white/10 px-4 py-4 font-mono text-[0.85rem] leading-relaxed break-all whitespace-pre-wrap text-[#e8e8ea]"><code><span v-for="command in commands" :key="command" class="block"><span class="text-[#9ee6a8] select-none">$ </span>{{ command }}</span></code></pre>
      </div>
    </UContainer>
  </section>
</template>
