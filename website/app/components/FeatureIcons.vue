<script setup lang="ts">
const features = [
  { icon: 'i-lucide-scissors', motion: 'snip', label: 'Real Command-X', text: 'Cut files in Finder, exactly like on Windows.' },
  { icon: 'i-lucide-clipboard-paste', motion: 'drop', label: 'Paste to move', text: 'Command-V moves them. No copies left behind.' },
  { icon: 'i-lucide-text-cursor-input', motion: 'blink', label: 'Text still works', text: 'Renaming or searching? Cutting text works as usual.' },
  { icon: 'i-lucide-volume-2', motion: 'pulse', label: 'Cut sound', text: 'Optional sound so you hear when files are cut.' },
  { icon: 'i-lucide-eye-off', motion: 'blink', label: 'Hide the icon', text: 'Hide it from the menu bar, it keeps working.' },
  { icon: 'i-lucide-shield-check', motion: 'nod', label: 'Zero tracking', text: 'No account, no analytics. Nothing leaves your Mac.' },
  { icon: 'i-lucide-cpu', motion: 'buzz', label: 'Universal app', text: 'Native on Apple Silicon and Intel, macOS 14+.' },
  { icon: 'i-lucide-heart', motion: 'beat', label: 'Free forever', text: 'Open source under the MIT license.' }
]
</script>

<template>
  <section id="features" class="scroll-mt-24 py-16 sm:py-28">
    <UContainer class="max-w-6xl">
      <h2 class="max-w-xl font-display text-[clamp(2.4rem,5.5vw,4rem)] leading-[1.02] font-black tracking-[-0.035em] text-highlighted">
        Small app.<br>One job. Done right.
      </h2>

      <ul class="mt-10 grid grid-cols-2 gap-x-5 gap-y-8 sm:mt-16 sm:gap-x-10 sm:gap-y-12 lg:grid-cols-4">
        <li v-for="feature in features" :key="feature.label" class="group">
          <span class="grid size-12 place-items-center rounded-[0.9rem] sm:size-16 sm:rounded-[1.15rem] border border-white/70 bg-[image:var(--icon-gradient)] shadow-[0_8px_18px_-10px_rgb(29_29_31/0.35),inset_0_1px_0_white]">
            <UIcon :name="feature.icon" class="size-5.5 text-[#2c2c2e] sm:size-7" :class="`motion-${feature.motion}`" />
          </span>
          <h3 class="mt-3 font-display text-base leading-tight font-extrabold text-highlighted sm:mt-5 sm:text-xl">
            {{ feature.label }}
          </h3>
          <p class="mt-1 max-w-[30ch] text-sm text-muted sm:mt-1.5 sm:text-base">
            {{ feature.text }}
          </p>
        </li>
      </ul>
    </UContainer>
  </section>
</template>

<style scoped>
.group:hover .motion-snip { animation: snip 0.5s ease-in-out 2; }
.group:hover .motion-drop { animation: drop 0.55s cubic-bezier(0.22, 1, 0.36, 1); }
.group:hover .motion-blink { animation: blink 0.5s ease-in-out; }
.group:hover .motion-pulse { animation: pulse 0.45s ease-in-out 2; }
.group:hover .motion-nod { animation: nod 0.6s ease-in-out; }
.group:hover .motion-buzz { animation: buzz 0.4s linear; }
.group:hover .motion-beat { animation: beat 0.8s ease-in-out; }

@keyframes snip {
  50% { transform: rotate(-18deg) scaleX(0.85); }
}

@keyframes drop {
  30% { transform: scale(0.84); }
  65% { transform: scale(1.08); }
}

@keyframes blink {
  45% { transform: scaleY(0.1); }
}

@keyframes pulse {
  50% { transform: scale(1.18); }
}

@keyframes nod {
  30% { transform: translateY(12%); }
  60% { transform: translateY(-6%); }
}

@keyframes buzz {
  20%, 60% { transform: translateX(-6%); }
  40%, 80% { transform: translateX(6%); }
}

@keyframes beat {
  15%, 45% { transform: scale(1.22); }
  30% { transform: scale(1); }
}

@media (prefers-reduced-motion: reduce) {
  .group:hover [class*='motion-'] {
    animation: none;
  }
}
</style>
