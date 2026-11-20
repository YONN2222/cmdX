export default defineEventHandler(() => cachedJsonResponse('stats', 'GitHub stats', fetchGithubStats))
