import { Download } from 'lucide-react'
import { BANNER_DATA_URI, LOGO_DATA_URI } from '@/lib/brandAssets'

const ASSETS = [
  { src: BANNER_DATA_URI, file: 'agent-bounty-board-x-banner.png', label: 'X banner', size: '1500 x 500' },
  { src: LOGO_DATA_URI, file: 'agent-bounty-board-x-logo.png', label: 'X profile picture', size: '400 x 400' },
]

/** Images for the project's X profile. They are embedded in the page, so saving never needs a network request. */
export function BrandKit() {
  return (
    <section className="card rounded-3xl p-5">
      <h2 className="text-sm font-semibold" style={{ color: 'var(--ink)' }}>
        Brand kit
      </h2>
      <div className="mt-3 space-y-4">
        {ASSETS.map((a) => (
          <div key={a.file}>
            <img
              src={a.src}
              alt={a.label}
              className="w-full rounded-2xl"
              style={{ border: '1px solid var(--border)', maxWidth: a.file.endsWith('logo.png') ? 160 : undefined }}
            />
            <a
              href={a.src}
              download={a.file}
              className="mt-2 flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold"
              style={{ background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink)' }}
            >
              <Download className="size-4" /> Download {a.label} ({a.size})
            </a>
          </div>
        ))}
      </div>
    </section>
  )
}
