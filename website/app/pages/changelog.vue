<script setup lang="ts">
import type { Release } from '~~/server/utils/github'

const { data: releases, error, refresh } = await useFetch<Release[]>('/api/releases', { key: 'github-releases' })
onMounted(() => refresh())

const { onDownload } = useDownload()

const title = 'cmdX Changelog: every release of the Finder cut & paste app'
const description = 'Release notes for cmdX, the free app that makes the Command-X shortcut cut files in macOS Finder. Download any version directly.'

useSeoMeta({ title, description, ogTitle: title, ogDescription: description, ogUrl: `${SITE_URL}/changelog`, twitterTitle: title, twitterDescription: description })
useHead({ link: [{ rel: 'canonical', href: `${SITE_URL}/changelog` }] })

const dateFormat = new Intl.DateTimeFormat('en', { year: 'numeric', month: 'long', day: 'numeric' })

function formatSize(bytes: number | null) {
  return bytes ? `${(bytes / 1024 / 1024).toFixed(1)} MB` : ''
}
</script>

<template>
  <main class="pt-14 pb-10">
    <UContainer class="max-w-4xl">
      <h1 class="enter font-display text-[clamp(3rem,8vw,5.5rem)] leading-[0.95] font-black tracking-[-0.04em] text-highlighted">
        Changelog
      </h1>
      <p class="enter mt-5 max-w-[56ch] text-lg text-muted [--enter-delay:120ms]">
        Every cmdX release, newest first. Download any version straight from here.
      </p>

      <div v-if="error && !releases?.length" class="mt-14 rounded-2xl bg-paper-deep p-6 text-muted">
        The release list could not be loaded right now.
        <a :href="LINKS.releases" target="_blank" rel="noopener" class="font-semibold text-highlighted underline underline-offset-4">See all releases on GitHub</a>.
      </div>

      <ol v-else class="mt-14">
        <li
          v-for="(release, index) in releases"
          :key="release.version"
          class="enter grid gap-4 border-t border-default py-10 md:grid-cols-[11rem_1fr]"
          :style="{ '--enter-delay': `${200 + Math.min(index, 6) * 70}ms` }"
        >
          <div class="flex items-start gap-3 md:flex-col">
            <span
              class="rounded-lg px-2.5 py-1 font-mono text-sm font-bold"
              :class="index === 0 ? 'bg-[image:var(--icon-gradient)] text-highlighted' : 'bg-paper-deep text-muted'"
            >v{{ release.version }}</span>
            <time :datetime="release.publishedAt" class="text-sm text-dimmed">{{ dateFormat.format(new Date(release.publishedAt)) }}</time>
          </div>

          <div class="min-w-0">
            <h2 class="font-display text-2xl font-extrabold text-highlighted">
              {{ release.name }}
            </h2>
            <div class="release-notes mt-3 text-muted" v-html="release.notesHtml" />

            <div class="mt-6 flex flex-wrap items-center gap-3">
              <a
                v-if="release.dmgUrl"
                :href="release.dmgUrl"
                rel="noopener"
                class="group inline-flex items-center gap-2 rounded-xl px-4 py-2.5 font-display font-extrabold transition-[background-color,transform] duration-200 active:scale-[0.96]"
                :class="index === 0 ? 'bg-[#232326] text-white hover:bg-[#303034]' : 'bg-paper-deep text-highlighted hover:bg-[#e4e4de]'"
                @click="onDownload('changelog', release.version)"
              >
                <IconSwap from="i-simple-icons-apple" to="i-lucide-arrow-down-to-line" />
                Download v{{ release.version }}
                <span class="font-mono text-xs font-medium opacity-60">{{ formatSize(release.dmgSize) }}</span>
              </a>
              <a
                :href="release.url"
                target="_blank"
                rel="noopener"
                class="group inline-flex items-center gap-1.5 rounded-xl px-3 py-2.5 text-sm font-semibold text-muted transition-colors hover:bg-paper-deep hover:text-highlighted"
                v-umami="{ name: 'github-click', location: 'changelog', version: release.version }"
              >
                <UIcon name="i-simple-icons-github" class="size-4 transition-transform duration-300 group-hover:-rotate-12" />
                View on GitHub
              </a>
            </div>
          </div>
        </li>
      </ol>
    </UContainer>
  </main>
</template>

<style scoped>
.release-notes :deep(h1),
.release-notes :deep(h2),
.release-notes :deep(h3) {
  margin-top: 1.2rem;
  font-family: var(--font-display);
  font-size: 1.1rem;
  font-weight: 800;
  color: var(--ui-text-highlighted);
}

.release-notes :deep(p) {
  margin-top: 0.6rem;
}

.release-notes :deep(ul) {
  margin-top: 0.6rem;
  padding-left: 1.2rem;
  list-style: disc;
}

.release-notes :deep(li) {
  margin-top: 0.3rem;
}

.release-notes :deep(a) {
  color: var(--ui-text-highlighted);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.release-notes :deep(code) {
  border-radius: 0.3rem;
  background: var(--ui-bg-muted);
  padding: 0.1rem 0.35rem;
  font-family: var(--font-mono);
  font-size: 0.85em;
}
</style>
