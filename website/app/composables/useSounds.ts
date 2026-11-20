const STORAGE_KEY = 'cmdx-sounds-muted'

let audioContext: AudioContext | null = null

function getContext(): AudioContext | null {
  if (typeof window === 'undefined') return null
  audioContext ??= new AudioContext()
  if (audioContext.state === 'suspended') void audioContext.resume()
  return audioContext
}

function noiseClick(context: AudioContext, start: number, frequency: number, volume: number) {
  const length = Math.floor(context.sampleRate * 0.03)
  const buffer = context.createBuffer(1, length, context.sampleRate)
  const data = buffer.getChannelData(0)
  for (let i = 0; i < length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / length) ** 3

  const source = context.createBufferSource()
  source.buffer = buffer
  const filter = context.createBiquadFilter()
  filter.type = 'bandpass'
  filter.frequency.value = frequency
  filter.Q.value = 1.2
  const gain = context.createGain()
  gain.gain.value = volume

  source.connect(filter).connect(gain).connect(context.destination)
  source.start(start)
}

function pop(context: AudioContext, start: number) {
  const oscillator = context.createOscillator()
  const gain = context.createGain()
  oscillator.frequency.setValueAtTime(720, start)
  oscillator.frequency.exponentialRampToValueAtTime(320, start + 0.09)
  gain.gain.setValueAtTime(0.0001, start)
  gain.gain.exponentialRampToValueAtTime(0.18, start + 0.01)
  gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.12)
  oscillator.connect(gain).connect(context.destination)
  oscillator.start(start)
  oscillator.stop(start + 0.13)
}

function chime(context: AudioContext, start: number) {
  const notes = [
    { frequency: 1318.5, at: 0 },
    { frequency: 1760, at: 0.11 }
  ]
  for (const note of notes) {
    for (const [ratio, level] of [[1, 0.12], [2.76, 0.025]] as const) {
      const oscillator = context.createOscillator()
      const gain = context.createGain()
      const t = start + note.at
      oscillator.type = 'sine'
      oscillator.frequency.value = note.frequency * ratio
      gain.gain.setValueAtTime(0.0001, t)
      gain.gain.exponentialRampToValueAtTime(level, t + 0.008)
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.9)
      oscillator.connect(gain).connect(context.destination)
      oscillator.start(t)
      oscillator.stop(t + 0.95)
    }
  }
}

export function useSounds() {
  const muted = useState('sounds-muted', () => false)

  onMounted(() => {
    try {
      muted.value = localStorage.getItem(STORAGE_KEY) === '1'
    }
    catch {
    }
  })

  function toggleMuted() {
    muted.value = !muted.value
    try {
      localStorage.setItem(STORAGE_KEY, muted.value ? '1' : '0')
    }
    catch {
    }
    if (!muted.value) playClick()
  }

  function play(sound: (context: AudioContext, now: number) => void) {
    if (muted.value) return
    const context = getContext()
    if (context) sound(context, context.currentTime)
  }

  const playClick = () => play((context, now) => noiseClick(context, now, 3200, 0.5))
  const playCut = () => play((context, now) => {
    noiseClick(context, now, 5200, 0.45)
    noiseClick(context, now + 0.07, 6400, 0.4)
  })
  const playPaste = () => play((context, now) => {
    noiseClick(context, now, 2600, 0.35)
    pop(context, now + 0.02)
  })

  const playChime = () => play(chime)

  return { muted, toggleMuted, playClick, playCut, playPaste, playChime }
}
