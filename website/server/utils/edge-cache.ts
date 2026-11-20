import type { H3Event } from 'h3'

const CACHE_SECONDS = 3600

export async function edgeCachedJson<T>(event: H3Event, label: string, load: () => Promise<T>): Promise<Response> {
  const cache = (globalThis as { caches?: { default?: Cache } }).caches?.default
  const cacheKey = new Request(getRequestURL(event).toString())

  const cached = await cache?.match(cacheKey)
  if (cached) return cached

  try {
    const response = new Response(JSON.stringify(await load()), {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': `public, max-age=${CACHE_SECONDS}`
      }
    })
    await cache?.put(cacheKey, response.clone())
    return response
  }
  catch (error) {
    console.error(`Failed to load ${label}`, error)
    throw createError({ statusCode: 502, statusMessage: `${label} unavailable` })
  }
}
