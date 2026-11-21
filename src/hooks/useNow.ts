import { useEffect, useState } from 'react'

/** Current unix time in seconds, refreshed every 20 seconds. */
export function useNow(): number {
  const [now, setNow] = useState(() => Math.floor(Date.now() / 1000))
  useEffect(() => {
    const id = setInterval(() => setNow(Math.floor(Date.now() / 1000)), 20_000)
    return () => clearInterval(id)
  }, [])
  return now
}
