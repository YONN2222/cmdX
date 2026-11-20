export default defineEventHandler(() => cachedJsonResponse('releases', 'GitHub releases', fetchReleases))
