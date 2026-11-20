<script setup lang="ts">
const { current, dismiss } = useMacNotification()

function runAction() {
  current.value?.action?.onClick?.()
  dismiss()
}
</script>

<template>
  <div class="pointer-events-none fixed top-20 right-4 z-50 w-[min(23rem,calc(100vw-2rem))]" aria-live="polite">
    <Transition name="notification">
      <div
        v-if="current"
        :key="current.id"
        class="mac-notification group pointer-events-auto relative rounded-[1.15rem] bg-[#f6f6f6]/80 p-3 shadow-[0_10px_30px_-8px_rgb(0_0_0/0.3),0_0_0_0.5px_rgb(0_0_0/0.18),inset_0_0.5px_0_rgb(255_255_255/0.8)] backdrop-blur-2xl backdrop-saturate-150"
        role="status"
      >
        <button
          type="button"
          class="absolute -top-2 -left-2 grid size-5 place-items-center rounded-full bg-[#f6f6f6] text-[#4a4a4f] opacity-0 shadow-[0_1px_3px_rgb(0_0_0/0.25),0_0_0_0.5px_rgb(0_0_0/0.15)] transition-opacity group-hover:opacity-100 focus-visible:opacity-100"
          aria-label="Close notification"
          @click="dismiss"
        >
          <UIcon name="i-lucide-x" class="size-3" />
        </button>

        <div class="flex gap-3">
          <img src="/cmdX.png" alt="" width="38" height="38" class="size-[38px] shrink-0 rounded-[9px]">
          <div class="min-w-0 flex-1">
            <div class="flex items-center justify-between text-[11px] font-medium text-[#77777e]">
              <span class="tracking-wide uppercase">cmdX</span>
              <span>now</span>
            </div>
            <p class="mt-0.5 text-[13px] leading-snug font-semibold text-[#1d1d1f]">
              {{ current.title }}
            </p>
            <p class="text-[13px] leading-snug text-[#3a3a3f]">
              {{ current.body }}
            </p>
          </div>
        </div>

        <a
          v-if="current.action"
          :href="current.action.href"
          target="_blank"
          rel="noopener"
          class="mt-2.5 flex items-center justify-center gap-1.5 rounded-[9px] bg-black/[0.06] py-1.5 text-[13px] font-medium text-[#1d1d1f] transition-colors hover:bg-black/[0.1]"
          @click="runAction"
        >
          <UIcon name="i-lucide-star" class="size-3.5" />
          {{ current.action.label }}
        </a>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.mac-notification {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Geist", sans-serif;
}

.notification-enter-active {
  transition: transform 0.45s cubic-bezier(0.22, 1.2, 0.36, 1), opacity 0.25s ease;
}

.notification-leave-active {
  transition: transform 0.3s ease-in, opacity 0.3s ease-in;
}

.notification-enter-from,
.notification-leave-to {
  opacity: 0;
  transform: translateX(110%);
}

@media (prefers-reduced-motion: reduce) {
  .notification-enter-active,
  .notification-leave-active {
    transition: opacity 0.2s ease;
  }

  .notification-enter-from,
  .notification-leave-to {
    transform: none;
  }
}
</style>
