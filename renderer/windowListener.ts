export function windowListener(events: Record<string, (event: any) => void>) {
  const logger = new Map<string, () => void>()
  return [
    () => {
      for (const [type, callback] of Object.entries(events)) {
        window.addEventListener(type, callback)
        const log = () => {
          console.log(`[window] ${type}`)
        }
        window.addEventListener(type, log)
        logger.set(type, log)
      }
    },
    () => {
      for (const [type, callback] of Object.entries(events)) {
        window.removeEventListener(type, callback)
        const log = logger.get(type)
        if (log) {
          window.removeEventListener(type, log)
          logger.delete(type)
        }
      }
    },
  ]
}
