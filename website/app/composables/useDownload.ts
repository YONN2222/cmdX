export function useDownload() {
  const umami = useUmami()
  const { playClick } = useSounds()
  const { notify } = useMacNotification()

  function onDownload(location: string, version?: string | null) {
    playClick()
    umami.track('download', { location, version: version ?? 'latest' })

    setTimeout(() => notify({
      title: 'Thanks for downloading!',
      body: 'If cmdX saves you a few clicks, a star on GitHub helps other Mac users find it.',
      action: {
        label: 'Star on GitHub',
        href: LINKS.repo,
        onClick: () => umami.track('star-prompt-click', { location })
      }
    }), 600)
  }

  return { onDownload }
}
