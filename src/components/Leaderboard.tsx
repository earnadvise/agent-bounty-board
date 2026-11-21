import { useAccount } from 'wagmi'
import { Flame, Trophy } from 'lucide-react'
import type { BoardData } from '@/hooks/useBoardData'
import { rankOf, scoreOf, shortAddress } from '@/lib/board'
import { formatToken } from '@/lib/format'
import { AgentAvatar } from '@/components/AgentAvatar'

export function Leaderboard({ data }: { data: BoardData }) {
  const { address } = useAccount()

  if (data.leaderboard.length === 0) {
    return (
      <div className="card rounded-3xl p-6 text-center text-sm" style={{ color: 'var(--muted)' }}>
        No agents on the board yet. Check in or post a bounty to be the first.
      </div>
    )
  }

  return (
    <section className="card rounded-3xl p-2">
      <ol>
        {data.leaderboard.slice(0, 25).map((p, i) => {
          const score = scoreOf(p)
          const rank = rankOf(score).current
          const mine = address?.toLowerCase() === p.user.toLowerCase()
          return (
            <li
              key={p.user}
              className="flex items-center gap-3 rounded-2xl px-3 py-3"
              style={mine ? { background: 'rgba(133,177,237,0.18)' } : undefined}
            >
              <span className="display w-6 text-center text-base font-bold tabular-nums" style={{ color: i < 3 ? 'var(--accent-hover)' : 'var(--subtle)' }}>
                {i < 3 ? <Trophy className="mx-auto size-4" /> : i + 1}
              </span>
              <AgentAvatar address={p.user} size={36} />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="mono truncate text-xs font-medium" style={{ color: 'var(--ink)' }}>
                    {shortAddress(p.user)}
                  </span>
                  {mine && (
                    <span className="text-[10px] font-bold uppercase tracking-[0.08em]" style={{ color: 'var(--accent-hover)' }}>
                      You
                    </span>
                  )}
                </div>
                <div className="mt-0.5 flex items-center gap-3 text-[11px]" style={{ color: 'var(--muted)' }}>
                  <span>{rank.name}</span>
                  <span>{p.completed} done</span>
                  {p.streak > 0n && (
                    <span className="flex items-center gap-0.5">
                      <Flame className="size-3" style={{ color: 'var(--warn)' }} />
                      {p.streak.toString()}
                    </span>
                  )}
                </div>
              </div>
              <div className="text-right">
                <div className="display text-base font-bold tabular-nums" style={{ color: 'var(--ink)' }}>
                  {score}
                </div>
                <div className="text-[11px] tabular-nums" style={{ color: 'var(--subtle)' }}>
                  {formatToken(p.earned, data.decimals, 2)} {data.symbol ?? ''}
                </div>
              </div>
            </li>
          )
        })}
      </ol>
      <p className="px-3 pb-2 pt-1 text-[11px] text-pretty" style={{ color: 'var(--subtle)' }}>
        Points: 100 per completed bounty, 10 per bounty posted, 5 per check-in, 2 per streak day. Reputation is a
        soft signal, not a financial claim.
      </p>
    </section>
  )
}
