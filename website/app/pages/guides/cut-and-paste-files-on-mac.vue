<script setup lang="ts">
const path = '/guides/cut-and-paste-files-on-mac'
const title = 'How to Cut and Paste Files on a Mac (Finder Guide)'
const description = 'Finder has no Cmd+X for files. Here are all the ways to cut and paste (move) files on a Mac: the hidden Cmd+Option+V shortcut, the Edit menu, drag and drop, and the free cmdX app.'

useSeoMeta({ title, description, ogTitle: title, ogDescription: description, ogUrl: `${SITE_URL}${path}`, ogType: 'article', twitterTitle: title, twitterDescription: description })

useHead({
  link: [{ rel: 'canonical', href: `${SITE_URL}${path}` }],
  script: [{
    type: 'application/ld+json',
    innerHTML: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'Article',
      'headline': title,
      'description': description,
      'url': `${SITE_URL}${path}`,
      'image': `${SITE_URL}/og.png`,
      'datePublished': '2026-11-20',
      'dateModified': '2026-11-20',
      'author': { '@type': 'Person', 'name': 'YONN2222', 'url': LINKS.author },
      'publisher': { '@type': 'Organization', 'name': 'cmdX', 'logo': { '@type': 'ImageObject', 'url': `${SITE_URL}/android-chrome-512x512.png` } }
    })
  }]
})

const comparison = [
  { label: 'Cut files with Cmd+X', builtIn: false, paid: true, cmdx: true },
  { label: 'Move files with Cmd+V', builtIn: false, paid: true, cmdx: true },
  { label: 'Cut text while renaming a file', builtIn: true, paid: false, cmdx: true },
  { label: 'Free', builtIn: true, paid: false, cmdx: true },
  { label: 'Open source', builtIn: false, paid: false, cmdx: true },
  { label: 'Works on macOS 14 Sonoma', builtIn: true, paid: false, cmdx: true }
]
</script>

<template>
  <main class="pt-14 pb-10">
    <UContainer class="guide max-w-3xl">
      <p class="text-sm text-dimmed">
        Updated November 2026
      </p>
      <h1 class="mt-3 font-display text-[clamp(2.4rem,6.5vw,4.2rem)] leading-[0.98] font-black tracking-[-0.04em] text-highlighted">
        How to cut and paste files on a Mac
      </h1>
      <p class="lead">
        On Windows you press Ctrl+X and Ctrl+V to move a file. On a Mac, Command-X does nothing in Finder when a file is
        selected. The good news: there are several ways to move files, and one of them makes Cmd+X work just like you expect.
      </p>

      <div class="answer">
        <p class="font-display text-lg font-extrabold text-highlighted">
          The short answer
        </p>
        <p>
          Select the files, press <MacKey name="command" /> <MacKey name="C" />, open the destination folder and press
          <MacKey name="command" /> <MacKey name="option" /> <MacKey name="V" />. Finder moves the files instead of copying them.
          If you would rather use <MacKey name="command" /> <MacKey name="X" /> like everywhere else, install
          <NuxtLink to="/">cmdX</NuxtLink>, a free app that adds it to Finder.
        </p>
      </div>

      <h2>Why doesn't Command-X work in Finder?</h2>
      <p>
        In Finder, Cut only works for text, for example while you rename a file. When files are selected, the Cut item in
        the Edit menu is grayed out and <MacKey name="command" /> <MacKey name="X" /> does nothing. Apple chose a
        "copy first, decide later" model instead: you copy the files and pick at paste time whether they are copied or moved.
        It is not a bug in your Mac, and there is no hidden setting to turn it on. The methods below are the ways around it.
      </p>

      <h2>Method 1: The hidden Finder shortcut</h2>
      <ol>
        <li>Select one or more files in Finder.</li>
        <li>Press <MacKey name="command" /> <MacKey name="C" /> to copy them. Nothing happens to the files yet.</li>
        <li>Open the folder where the files should go.</li>
        <li>Press <MacKey name="command" /> <MacKey name="option" /> <MacKey name="V" />. The files are moved and disappear from the original folder.</li>
      </ol>
      <p>
        It works well once you know it, but it is easy to forget. Press plain <MacKey name="command" /> <MacKey name="V" /> by
        habit and you end up with a copy instead of a move.
      </p>

      <h2>Method 2: The Edit menu</h2>
      <p>
        Copy the files with <MacKey name="command" /> <MacKey name="C" />, go to the destination folder and open the
        <strong>Edit</strong> menu in the menu bar. Hold the <MacKey name="option" /> Option key: "Paste Item" turns into
        <strong>"Move Item Here"</strong>. Click it to move the files.
      </p>

      <h2>Method 3: Drag and drop</h2>
      <p>
        Dragging a file to another folder on the same drive moves it. Dragging it to a different drive or USB stick copies
        it instead. Hold <MacKey name="command" /> while dragging to force a move between drives. This works, but it needs two
        Finder windows side by side and a steady hand.
      </p>

      <h2>Method 4: Real Cmd+X with cmdX</h2>
      <p>
        <NuxtLink to="/">cmdX</NuxtLink> is a small, free and open source menu bar app that makes Finder behave like every
        other system:
      </p>
      <ol>
        <li><a :href="LINKS.releases" target="_blank" rel="noopener">Download cmdX</a> or install it with Homebrew: <code>brew install cmdx</code> after adding the tap.</li>
        <li>Open it and allow Accessibility access when macOS asks. cmdX needs this to see the shortcut while Finder is in front.</li>
        <li>Select files and press <MacKey name="command" /> <MacKey name="X" />, then press <MacKey name="command" /> <MacKey name="V" /> in any other folder.</li>
      </ol>
      <p>
        Cutting text still works as usual while you rename a file or type in the Finder search field, and nothing leaves
        your Mac: no account, no tracking.
      </p>

      <h2>Built-in Finder vs. paid apps vs. cmdX</h2>
      <div class="mt-6 overflow-x-auto rounded-2xl border border-default bg-elevated">
        <table class="w-full min-w-[32rem] text-left text-sm">
          <thead>
            <tr class="border-b border-default">
              <th class="p-4 font-semibold text-muted" />
              <th class="p-4 font-display font-extrabold text-highlighted">Built-in Finder</th>
              <th class="p-4 font-display font-extrabold text-highlighted">Typical paid Cmd+X apps</th>
              <th class="p-4 font-display font-extrabold text-highlighted">cmdX</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in comparison" :key="row.label" class="border-b border-default last:border-0">
              <td class="p-4 text-highlighted">{{ row.label }}</td>
              <td v-for="(value, index) in [row.builtIn, row.paid, row.cmdx]" :key="index" class="p-4">
                <UIcon :name="value ? 'i-lucide-check' : 'i-lucide-minus'" :class="value ? 'text-[#2f9e5b]' : 'text-dimmed'" class="size-5" />
                <span class="sr-only">{{ value ? 'Yes' : 'No' }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-3 text-sm text-dimmed">
        Paid apps differ in price and supported macOS versions; many require the newest macOS and block cutting text in
        Finder's rename and search fields.
      </p>

      <div class="mt-14 flex flex-col items-start gap-4 rounded-3xl bg-paper-deep p-8">
        <p class="font-display text-2xl font-black tracking-tight text-highlighted">
          Get Cmd+X in Finder for free
        </p>
        <p class="text-muted">
          cmdX runs on Apple Silicon and Intel Macs with macOS 14 or later.
        </p>
        <DownloadKey location="guide" />
      </div>
    </UContainer>
  </main>
</template>

<style scoped>
.guide .lead {
  margin-top: 1.4rem;
  font-size: 1.15rem;
  line-height: 1.7;
  color: var(--ui-text-muted);
}

.guide .answer {
  margin-top: 2rem;
  border-radius: 1.4rem;
  background: var(--icon-gradient);
  padding: 1.5rem;
}

.guide .answer p + p {
  margin-top: 0.5rem;
  line-height: 1.8;
  color: var(--ui-text);
}

.guide h2 {
  margin-top: 3rem;
  font-family: var(--font-display);
  font-size: 1.7rem;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: var(--ui-text-highlighted);
}

.guide p:not(.lead):not(.text-sm):not(.font-display) {
  margin-top: 0.9rem;
  line-height: 1.8;
  color: var(--ui-text-muted);
}

.guide ol {
  margin-top: 1rem;
  padding-left: 1.3rem;
  list-style: decimal;
  line-height: 1.8;
  color: var(--ui-text-muted);
}

.guide li + li {
  margin-top: 0.4rem;
}

.guide a:not(.btn-key),
.guide :deep(a:not(.btn-key)) {
  color: var(--ui-text-highlighted);
  font-weight: 600;
  text-decoration: underline;
  text-underline-offset: 3px;
}

.guide code {
  border-radius: 0.35rem;
  background: var(--ui-bg-muted);
  padding: 0.1rem 0.4rem;
  font-family: var(--font-mono);
  font-size: 0.85em;
}
</style>
