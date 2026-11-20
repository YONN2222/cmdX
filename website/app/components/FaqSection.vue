<script setup lang="ts">
const faqs = [
  {
    label: 'What is cmdX?',
    content: 'cmdX is a free, open source macOS app that adds real cut and paste to Finder. Its name comes from the Command-X shortcut it brings to Finder: press Cmd+X to cut files and Cmd+V to move them to a new folder.'
  },
  {
    label: 'Doesn\'t macOS already support cutting files?',
    content: 'Only halfway. Finder lets you copy with Cmd+C and then move with Cmd+Option+V, but that trick is hard to discover and works differently from every other app and operating system. cmdX makes Cmd+X and Cmd+V in Finder behave the way you expect.'
  },
  {
    label: 'How is cmdX different from other cut and paste apps for Finder?',
    content: 'cmdX is completely free and open source, runs on macOS 14 Sonoma and later, and still lets you cut text while renaming a file or typing in the Finder search field. Some paid alternatives need the newest macOS and block Cmd+X in those text fields.'
  },
  {
    label: 'Is cmdX safe to use?',
    content: 'Yes. The full source code is on GitHub for anyone to review. cmdX needs Accessibility permission to see keyboard shortcuts while Finder is in front, but it does not collect, store or send any data.'
  },
  {
    label: 'Which Macs and macOS versions are supported?',
    content: 'cmdX is a universal binary for Apple Silicon (M1, M2, M3, M4 and newer) and Intel Macs, running macOS 14 Sonoma or later, including the newest macOS releases.'
  },
  {
    label: 'Can I still cut text when renaming files?',
    content: 'Yes. When you rename a file or type in the Finder search field, Cmd+X cuts text as usual. cmdX only steps in when files are selected.'
  },
  {
    label: 'How do I install cmdX with Homebrew?',
    content: 'Run "brew tap YONN2222/cmdx https://github.com/YONN2222/cmdX" and then "brew install cmdx". The tap is kept in sync with GitHub Releases, so brew upgrade always finds the latest version.'
  },
  {
    label: 'How do I uninstall cmdX?',
    content: 'Quit cmdX from the menu bar and move it from Applications to the Trash. You can also remove it from System Settings, Privacy & Security, Accessibility.'
  },
  {
    label: 'Is cmdX really free?',
    content: 'Yes. cmdX is MIT licensed, with no subscription, no in-app purchases and no ads. Contributions on GitHub are always welcome.'
  }
]

useHead({
  script: [{
    type: 'application/ld+json',
    innerHTML: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      'mainEntity': faqs.map(faq => ({
        '@type': 'Question',
        'name': faq.label,
        'acceptedAnswer': { '@type': 'Answer', 'text': faq.content }
      }))
    })
  }]
})
</script>

<template>
  <section id="faq" class="scroll-mt-20 bg-paper-deep py-24">
    <UContainer class="max-w-5xl">
      <h2 class="text-center font-display text-[clamp(2.2rem,5vw,3.6rem)] font-black tracking-[-0.03em] text-highlighted">
        Questions? Answers.
      </h2>
      <dl class="mt-14 grid gap-x-14 gap-y-10 md:grid-cols-2">
        <div v-for="faq in faqs" :key="faq.label">
          <dt class="font-display text-xl leading-snug font-extrabold text-highlighted">
            {{ faq.label }}
          </dt>
          <dd class="mt-2 leading-relaxed text-muted">
            {{ faq.content }}
          </dd>
        </div>
      </dl>
    </UContainer>
  </section>
</template>
