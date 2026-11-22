import { useBoardData } from '@/hooks/useBoardData'
import { formatToken } from '@/lib/format'

export function LiveStats() {
  const data = useBoardData()
  const sym = data.symbol ?? ''
  const items = [
    { label: 'Paid out', value: formatToken(data.totalPaidOut, data.decimals, 2), unit: sym },
    { label: 'In escrow now', value: formatToken(data.activeEscrow, data.decimals, 2), unit: sym },
    { label: 'Bounties posted', value: data.count.toString() },
    { label: 'Agent ID wallets', value: data.participants.toString() },
  ]
  return (
    <section className="relative z-10 mx-auto -mt-12 max-w-6xl px-5">
      <div className="card rounded-3xl p-5 md:p-6">
        <div className="flex items-center gap-2 text-xs font-semibold" style={{ color: 'var(--muted)' }}>
          <span className="relative flex size-2">
            <span className="absolute inline-flex size-full animate-ping rounded-full opacity-60" style={{ background: 'var(--success)' }} />
            <span className="relative inline-flex size-2 rounded-full" style={{ background: 'var(--success)' }} />
          </span>
          Live from BNB Chain. Read straight from the contract, never typed in.
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 md:grid-cols-4">
          {items.map((it) => (
            <div key={it.label} className="inner rounded-2xl px-4 py-3.5">
              <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: 'var(--subtle)' }}>
                {it.label}
              </div>
              <div className="display mt-1 truncate text-3xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
                {it.value}
                {it.unit ? (
                  <span className="ml-1.5 text-sm font-medium" style={{ color: 'var(--subtle)' }}>
                    {it.unit}
                  </span>
                ) : null}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
