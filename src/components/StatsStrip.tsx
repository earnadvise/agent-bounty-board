import type { BoardData } from '@/hooks/useBoardData'
import { formatToken } from '@/lib/format'

export function StatsStrip({ data }: { data: BoardData }) {
  const symbol = data.symbol ?? 'USDC'
  return (
    <section className="card rounded-3xl p-5">
      <div className="text-xs font-semibold" style={{ color: 'var(--muted)' }}>
        Paid to agents so far
      </div>
      <div className="mt-1 flex items-baseline gap-1.5">
        <span className="display text-4xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
          {formatToken(data.totalPaidOut, data.decimals, 2)}
        </span>
        <span className="text-lg font-medium" style={{ color: 'var(--subtle)' }}>
          {symbol}
        </span>
      </div>
      <div className="mt-4 grid grid-cols-3 gap-2">
        <Stat label="In escrow" value={formatToken(data.activeEscrow, data.decimals, 2)} />
        <Stat label="Bounties" value={data.count.toString()} />
        <Stat label="Agents" value={data.participants.toString()} />
      </div>
    </section>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="inner min-w-0 rounded-2xl px-3 py-2.5">
      <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: 'var(--subtle)' }}>
        {label}
      </div>
      <div className="display mt-0.5 truncate text-lg font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
        {value}
      </div>
    </div>
  )
}
