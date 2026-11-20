const REPO_API = 'https://api.github.com/repos/YONN2222/cmdX'

export interface Release {
  version: string
  name: string
  publishedAt: string
  notesHtml: string
  url: string
  dmgUrl: string | null
  dmgSize: number | null
  downloads: number
}

export interface GithubStats {
  downloads: number
  stars: number
  version: string | null
  dmgUrl: string | null
}

interface ApiAsset {
  name: string
  size: number
  download_count: number
  browser_download_url: string
}

interface ApiRelease {
  tag_name: string
  name: string | null
  draft: boolean
  prerelease: boolean
  published_at: string
  html_url: string
  body_html?: string
  assets: ApiAsset[]
}

function githubHeaders(accept: string): Record<string, string> {
  const headers: Record<string, string> = { 'User-Agent': 'cmdx-website', 'Accept': accept }
  const token = useRuntimeConfig().githubToken
  if (token) headers.Authorization = `Bearer ${token}`
  return headers
}

function toRelease(release: ApiRelease): Release {
  const dmg = release.assets.find(asset => asset.name.endsWith('.dmg'))
  const version = release.tag_name.replace(/^v/, '')
  return {
    version,
    name: release.name || version,
    publishedAt: release.published_at,
    notesHtml: release.body_html ?? '',
    url: release.html_url,
    dmgUrl: dmg?.browser_download_url ?? null,
    dmgSize: dmg?.size ?? null,
    downloads: release.assets.reduce((sum, asset) => sum + asset.download_count, 0)
  }
}

export const fetchReleases = defineCachedFunction(async (): Promise<Release[]> => {
  const releases = await $fetch<ApiRelease[]>(`${REPO_API}/releases`, {
    headers: githubHeaders('application/vnd.github.html+json'),
    query: { per_page: 100 }
  })
  return releases.filter(release => !release.draft && !release.prerelease).map(toRelease)
}, { name: 'github-releases', maxAge: 60 * 60, getKey: () => 'cmdx' })

export const fetchGithubStats = defineCachedFunction(async (): Promise<GithubStats> => {
  const [releases, repo] = await Promise.all([
    fetchReleases(),
    $fetch<{ stargazers_count: number }>(REPO_API, { headers: githubHeaders('application/vnd.github+json') })
  ])
  const latest = releases[0]
  return {
    downloads: releases.reduce((sum, release) => sum + release.downloads, 0),
    stars: repo.stargazers_count,
    version: latest?.version ?? null,
    dmgUrl: latest?.dmgUrl ?? null
  }
}, { name: 'github-stats', maxAge: 60 * 60, getKey: () => 'cmdx' })
