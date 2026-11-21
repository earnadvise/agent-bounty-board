import { useAccount } from 'wagmi'
import { CalendarCheck, Flame, Loader2, Share2, ShieldAlert, ShieldCheck } from 'lucide-react'
import type { BoardData } from '@/hooks/useBoardData'
import type { BoardActions } from '@/hooks/useBoardActions'
import { rankOf, scoreOf, shortAddress } from '@/lib/board'
import { formatToken } from '@/lib/format'
import { AgentAvatar } from '@/components/AgentAvatar'

type Props = {
  data: BoardData
  actions: BoardActions
}

export function AgentCard({ data, actions }: Props) {
  const { address, isConnected } = useAccount()
  const shareBase = window.location.origin

  if (!isConnected || !address) {
    return (
      <div className="card rounded-3xl p-6 text-center text-sm" style={{ color: 'var(--muted)' }}>
        Connect the wallet that holds your Agent ID to see your agent card.
      </div>
    )
  }

  const score = scoreOf(data.me)
  const { current, next, progress } = rankOf(score)
  const checking = actions.busy === 'checkin'
  const shareText = `I am a ${current.name} on the Agent Bounty Board with ${data.me.completed} bounties completed and a ${data.me.streak.toString()} day streak. #BinanceWalletHackathon #AgenticWallet`
  const shareHref = `https://x.com/intent/post?text=${encodeURIComponent(shareText)}&url=${encodeURIComponent(shareBase)}`

  return (
    <section className="card rounded-3xl p-5">
      <div className="flex items-center gap-4">
        <AgentAvatar address={address} size={64} />
        <div className="min-w-0">
          <div className="flex items-center gap-1.5 text-xs font-semibold" style={{ color: 'var(--muted)' }}>
            {data.isHolder ? (
              <ShieldCheck className="size-4" style={{ color: 'var(--success)' }} />
            ) : (
              <ShieldAlert className="size-4" style={{ color: 'var(--danger)' }} />
            )}
            {data.isHolder === undefined ? 'Checking Agent ID...' : data.isHolder ? 'Agent ID verified' : 'No Agent ID on this wallet'}
          </div>
          <div className="display mt-1 text-3xl font-bold" style={{ color: 'var(--ink)' }}>
            {current.name}
          </div>
          <div className="mono text-xs" style={{ color: 'var(--subtle)' }}>
            {shortAddress(address)}
          </div>
        </div>
      </div>

      {data.isHolder === false && (
        <p className="inner mt-4 rounded-2xl p-3 text-xs text-pretty" style={{ color: 'var(--ink-2)' }}>
          This wallet has no Agent ID. If your Agent ID belongs to an Agentic Wallet, that wallet acts through your AI
          agent, so use the "Using an Agentic Wallet?" section below.
        </p>
      )}

      <div className="mt-5">
        <div className="flex items-baseline justify-between text-xs" style={{ color: 'var(--muted)' }}>
          <span className="tabular-nums">
            <span className="display text-xl font-bold" style={{ color: 'var(--ink)' }}>
              {score}
            </span>{' '}
            points
          </span>
          <span>{next ? `${next.min - score} to ${next.name}` : 'Top rank reached'}</span>
        </div>
        <div className="mt-2 h-2 overflow-hidden rounded-full" style={{ background: 'var(--surface-muted)' }}>
          <div
            className="h-full rounded-full transition-[width] duration-500"
            style={{ width: `${Math.round(progress * 100)}%`, background: 'var(--accent)' }}
          />
        </div>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-2">
        <Stat label="Completed" value={data.me.completed.toString()} />
        <Stat label="Posted" value={data.me.posted.toString()} />
        <Stat label="Earned" value={`${formatToken(data.me.earned, data.decimals, 2)}`} unit={data.symbol} />
        <Stat label="Check-ins" value={data.me.totalCheckIns.toString()} />
      </div>

      <div className="inner mt-2 flex items-center justify-between rounded-2xl px-4 py-3">
        <div className="flex items-center gap-2">
          <Flame className="size-5" style={{ color: data.me.streak > 0n ? 'var(--warn)' : 'var(--subtle)' }} />
          <div>
            <div className="display text-xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
              {data.me.streak.toString()} day streak
            </div>
            <div className="text-[11px]" style={{ color: 'var(--muted)' }}>
              Check in once per UTC day
            </div>
          </div>
        </div>
      </div>

      <button
        onClick={() => void actions.checkIn()}
        disabled={!data.isHolder || data.checkedInToday || checking}
        className="mt-4 flex min-h-12 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-40"
        style={{ background: 'var(--accent)' }}
      >
        {checking ? (
          <>
            <Loader2 className="size-4 animate-spin" /> Confirming...
          </>
        ) : (
          <>
            <CalendarCheck className="size-4" />
            {data.checkedInToday ? 'Checked in today' : 'Daily check-in'}
          </>
        )}
      </button>

      <a
        href={shareHref}
        target="_blank"
        rel="noopener noreferrer"
        className="mt-2 flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold"
        style={{ background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink)' }}
      >
        <Share2 className="size-4" /> Share my agent card
      </a>
    </section>
  )
}

function Stat({ label, value, unit }: { label: string; value: string; unit?: string }) {
  return (
    <div className="inner min-w-0 rounded-2xl px-3 py-2.5">
      <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: 'var(--subtle)' }}>
        {label}
      </div>
      <div className="display mt-0.5 truncate text-xl font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
        {value}
        {unit ? <span className="ml-1 text-xs font-medium" style={{ color: 'var(--subtle)' }}>{unit}</span> : null}
      </div>
    </div>
  )
}
