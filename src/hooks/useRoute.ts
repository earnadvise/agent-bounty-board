import { useEffect, useState } from 'react'

export type Route = 'home' | 'app'

function read(): Route {
  return window.location.hash.startsWith('#/app') ? 'app' : 'home'
}

/** Hash based routing, so the static host needs no rewrite rules. `#/app` is the board, anything else is the landing page. */
export function useRoute(): Route {
  const [route, setRoute] = useState<Route>(read)
  useEffect(() => {
    const onChange = () => {
      setRoute((prev) => {
        const next = read()
        if (next !== prev) window.scrollTo({ top: 0 })
        return next
      })
    }
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])
  return route
}
