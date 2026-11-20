<script setup lang="ts">
export type MacFileKind = 'folder' | 'pdf' | 'image' | 'dmg' | 'markdown'

const props = defineProps<{ kind: MacFileKind }>()

const badges: Record<Exclude<MacFileKind, 'folder' | 'image'>, { label: string, color: string }> = {
  pdf: { label: 'PDF', color: '#e5483a' },
  dmg: { label: 'DMG', color: '#8e8e93' },
  markdown: { label: 'MD', color: '#3a3a3c' }
}

const badge = computed(() => (props.kind === 'folder' || props.kind === 'image' ? null : badges[props.kind]))
</script>

<template>
  <svg v-if="kind === 'folder'" viewBox="0 0 64 52" class="drop-shadow-[0_1px_1px_rgb(0_0_0/0.18)]" aria-hidden="true">
    <defs>
      <linearGradient id="folder-front" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#8ccfff" />
        <stop offset="1" stop-color="#5cb3f6" />
      </linearGradient>
    </defs>
    <path d="M4 6a4 4 0 0 1 4-4h14.5a4 4 0 0 1 3 1.35L28 6h28a4 4 0 0 1 4 4v4H4z" fill="#4fa3e8" />
    <rect x="4" y="11" width="56" height="39" rx="4" fill="url(#folder-front)" />
    <rect x="4" y="11" width="56" height="1.5" fill="#b7e2ff" opacity="0.9" />
  </svg>

  <svg v-else viewBox="0 0 52 64" class="drop-shadow-[0_1px_1.5px_rgb(0_0_0/0.22)]" aria-hidden="true">
    <path d="M6 2h28l14 14v42a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V6a4 4 0 0 1 4-4z" fill="#ffffff" stroke="#d4d4d8" stroke-width="1" />
    <path d="M34 2v10a4 4 0 0 0 4 4h10" fill="#ececf0" stroke="#d4d4d8" stroke-width="1" />

    <template v-if="kind === 'image'">
      <rect x="8" y="22" width="34" height="26" rx="2" fill="#bfe3ff" />
      <circle cx="33" cy="29" r="3.2" fill="#ffd34d" />
      <path d="M8 44l10-11 7 7 5-5 12 12v1a2 2 0 0 1-2 2H10a2 2 0 0 1-2-2z" fill="#4caf6a" />
    </template>

    <template v-else-if="badge">
      <g fill="#c7c7cc">
        <rect x="9" y="22" width="30" height="2.4" rx="1.2" />
        <rect x="9" y="28" width="26" height="2.4" rx="1.2" />
        <rect x="9" y="34" width="30" height="2.4" rx="1.2" />
      </g>
      <rect x="6" y="44" width="38" height="12" rx="3" :fill="badge.color" />
      <text x="25" y="53" text-anchor="middle" font-family="-apple-system, Geist, sans-serif" font-size="8.5" font-weight="700" fill="#ffffff">{{ badge.label }}</text>
    </template>
  </svg>
</template>
