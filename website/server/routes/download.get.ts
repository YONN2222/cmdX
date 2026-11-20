const RELEASES_PAGE = 'https://github.com/YONN2222/cmdX/releases/latest'

export default defineEventHandler(async (event) => {
  try {
    const { dmgUrl } = await fetchGithubStats()
    return sendRedirect(event, dmgUrl ?? RELEASES_PAGE, 302)
  }
  catch (error) {
    console.error('Falling back to the releases page for /download', error)
    return sendRedirect(event, RELEASES_PAGE, 302)
  }
})
