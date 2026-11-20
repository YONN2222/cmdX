import type { GithubStats } from '~~/server/utils/github'

export function useGithubStats() {
  return useFetch<GithubStats>('/api/stats', { key: 'github-stats' })
}
