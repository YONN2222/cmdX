export function useSectionTracking(sectionIds: string[]) {
  const umami = useUmami()
  let observer: IntersectionObserver | undefined

  onMounted(() => {
    observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue
        umami.track('section-view', { section: entry.target.id })
        observer?.unobserve(entry.target)
      }
    }, { threshold: 0.4 })

    for (const id of sectionIds) {
      const element = document.getElementById(id)
      if (element) observer.observe(element)
    }
  })

  onBeforeUnmount(() => observer?.disconnect())
}
