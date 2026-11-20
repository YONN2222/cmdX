export default defineEventHandler(event => edgeCachedJson(event, 'GitHub stats', fetchGithubStats))
