const CACHE_SECONDS = 3600
const CACHE_ORIGIN = 'https://cache.cmdx.internal'

function edgeCache(): Cache | undefined {
  return (globalThis as { caches?: { default?: Cache } }).caches?.default
}

export async function edgeCached<T>(key: string, load: () => Promise<T>): Promise<T> {
  const cache = edgeCache()
  const cacheKey = new Request(`${CACHE_ORIGIN}/${key}`)

  const cached = await cache?.match(cacheKey)
  if (cached) return cached.json() as Promise<T>

  const data = await load()
  await cache?.put(cacheKey, new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json', 'Cache-Control': `public, max-age=${CACHE_SECONDS}` }
  }))
  return data
}

export async function cachedJsonResponse<T>(key: string, label: string, load: () => Promise<T>): Promise<T> {
  try {
    return await edgeCached(key, load)
  }
  catch (error) {
    console.error(`Failed to load ${label}`, error)
    throw createError({ statusCode: 502, statusMessage: `${label} unavailable` })
  }
}
