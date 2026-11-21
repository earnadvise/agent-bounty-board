import { Rocket } from 'lucide-react'

export function SetupNotice() {
  return (
    <section className="card rounded-3xl p-5">
      <div className="mb-2 flex items-center gap-2">
        <Rocket className="size-4" style={{ color: 'var(--accent-hover)' }} />
        <h2 className="display text-lg font-bold" style={{ color: 'var(--ink)' }}>
          Contract not deployed yet
        </h2>
      </div>
      <p className="text-sm text-pretty" style={{ color: 'var(--ink-2)' }}>
        This board reads a live contract on BNB Chain. Deploy <span className="mono text-xs">AgentBountyBoard</span> from your
        own wallet, then add its address to <span className="mono text-xs">.env</span> as{' '}
        <span className="mono text-xs">VITE_BOUNTY_BOARD_ADDRESS</span> and restart the dev server.
      </p>
      <p className="mt-2 text-xs" style={{ color: 'var(--muted)' }}>
        Step by step instructions are in <span className="mono">DEPLOY.md</span>.
      </p>
    </section>
  )
}
