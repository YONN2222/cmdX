export interface MacNotificationAction {
  label: string
  href: string
  onClick?: () => void
}

export interface MacNotification {
  id: number
  title: string
  body: string
  action?: MacNotificationAction
}

const DISPLAY_MS = 9000

let timer: ReturnType<typeof setTimeout> | undefined

export function useMacNotification() {
  const current = useState<MacNotification | null>('mac-notification', () => null)
  const { playChime } = useSounds()

  function dismiss() {
    clearTimeout(timer)
    current.value = null
  }

  function notify(notification: Omit<MacNotification, 'id'>) {
    clearTimeout(timer)
    current.value = { ...notification, id: Date.now() }
    playChime()
    timer = setTimeout(dismiss, DISPLAY_MS)
  }

  return { current, notify, dismiss }
}
