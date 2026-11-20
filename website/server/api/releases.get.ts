export default defineEventHandler(event => edgeCachedJson(event, 'GitHub releases', fetchReleases))
