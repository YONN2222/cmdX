<script setup lang="ts">
useSeoMeta({ title: 'Privacy Policy | cmdX', description: 'How the cmdX website handles your data.', robots: 'noindex, follow' })
useHead({ link: [{ rel: 'canonical', href: `${SITE_URL}/privacy` }] })
</script>

<template>
  <main class="pt-14 pb-10">
    <UContainer class="legal max-w-3xl">
      <h1 class="font-display text-[clamp(2.6rem,7vw,4.5rem)] leading-[0.95] font-black tracking-[-0.04em] text-highlighted">
        Privacy Policy
      </h1>
      <p class="mt-4 text-sm text-dimmed">
        Last updated: November 2026
      </p>

      <h2>Who is responsible</h2>
      <p>
        This website is run by the developer of cmdX, known on GitHub as
        <a :href="LINKS.author" target="_blank" rel="noopener">YONN2222</a>.
        For anything privacy related, please get in touch via
        <a :href="LINKS.contact" target="_blank" rel="noopener">yonn2222.com</a>.
      </p>

      <h2>The short version</h2>
      <p>
        This website introduces cmdX, a free and open source Mac app. There are no accounts, no forms, no newsletter
        and no ads, and we do not use cookies. We only process data needed to run the website and to understand how it
        is used, as described below.
      </p>

      <h2>Hosting with Cloudflare</h2>
      <p>
        The website is served by Cloudflare Workers (Cloudflare, Inc., 101 Townsend St., San Francisco, CA 94107, USA).
        When you visit, Cloudflare processes technical data such as your IP address, the time of the request, the page
        requested and browser and device information, in order to deliver the site and protect it from attacks.
      </p>
      <p>
        We rely on our legitimate interest in a secure and fast website (Art. 6(1)(f) GDPR). Cloudflare processes this
        data on our behalf and is certified under the EU-US Data Privacy Framework.
      </p>

      <h2>Analytics with Umami</h2>
      <p>
        We use Umami, a privacy-friendly open source analytics tool that we host ourselves (umami.yonn2222.com). The data
        is not shared with anyone else. Umami does not use cookies and does not build profiles across websites or devices.
        Requests are routed through this website.
      </p>
      <p>We collect:</p>
      <ul>
        <li>pages visited, time on page, referring website, browser, operating system, device type, screen size, language and country (derived from the IP address; the IP address itself is not stored),</li>
        <li>interactions such as clicks on download buttons, use of the demo, copying the Homebrew command and which sections were viewed,</li>
        <li>page load performance (Web Vitals) and technical errors, so we can find and fix problems,</li>
        <li>
          session recordings and heatmaps for a share of visits: mouse movements, clicks, scrolling and page changes are
          recorded to improve the usability of the site. Anything typed into input fields is masked and never recorded.
        </li>
      </ul>
      <p>
        To tell visits apart, Umami creates an identifier from shortened attributes such as IP address, browser and date,
        which changes every day. It does not allow us to identify you.
      </p>
      <p>
        We rely on our legitimate interest in understanding and improving our website (Art. 6(1)(f) GDPR). You can object
        to this at any time by contacting us via yonn2222.com. Many tracker-blocking browser extensions also block it.
      </p>

      <h2>Downloads via GitHub</h2>
      <p>
        The app files are hosted on GitHub (GitHub, Inc., 88 Colin P Kelly Jr St, San Francisco, CA 94107, USA). When you
        click a download button or a GitHub link, your browser connects to GitHub directly, which receives your IP address
        and technical browser data. Please see GitHub's privacy statement for details. Release information and download
        counts on this site are fetched by our server without sending any data about you.
      </p>

      <h2>Fonts</h2>
      <p>
        All fonts are served by this website itself. Your browser does not connect to Google or any other font provider.
      </p>

      <h2>Storage in your browser</h2>
      <p>
        If you mute the website's sounds, this setting is saved in your browser's local storage so it is remembered next
        time. It never leaves your device and is only saved when you choose to mute.
      </p>

      <h2>Your rights</h2>
      <p>You have the right to</p>
      <ul>
        <li>access the data we process about you,</li>
        <li>have it corrected, deleted or its processing restricted,</li>
        <li>receive it in a portable format,</li>
        <li><strong>object</strong> to processing based on our legitimate interest.</li>
      </ul>
      <p>
        Just contact us via <a :href="LINKS.contact" target="_blank" rel="noopener">yonn2222.com</a>.
        You can also lodge a complaint with a data protection supervisory authority.
      </p>

      <h2>How long we keep data</h2>
      <p>
        We keep data only as long as it is needed for its purpose. Cloudflare request logs are deleted automatically after
        a short time. Analytics data in Umami is kept only as long as we need it to improve the website.
      </p>
    </UContainer>
  </main>
</template>

<style scoped>
.legal h2 {
  margin-top: 2.6rem;
  font-family: var(--font-display);
  font-size: 1.4rem;
  font-weight: 800;
  color: var(--ui-text-highlighted);
}

.legal p,
.legal ul {
  margin-top: 0.8rem;
  max-width: 68ch;
  line-height: 1.7;
  color: var(--ui-text-muted);
}

.legal ul {
  padding-left: 1.2rem;
  list-style: disc;
}

.legal li {
  margin-top: 0.35rem;
}

.legal a {
  color: var(--ui-text-highlighted);
  text-decoration: underline;
  text-underline-offset: 3px;
}
</style>
