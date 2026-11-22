import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Plus } from 'lucide-react'
import type { BoardData } from '@/hooks/useBoardData'
import type { BoardActions } from '@/hooks/useBoardActions'
import { CATEGORIES, STATUS } from '@/lib/board'
import { BountyCard } from '@/components/BountyCard'

type Props = {
  data: BoardData
  actions: BoardActions
  now: number
  onPost: () => void
}

type View = 'open' | 'mine' | 'all'

export function BoardTab({ data, actions, now, onPost }: Props) {
  const { address, isConnected } = useAccount()
  const [view, setView] = useState<View>('open')
  const [category, setCategory] = useState<number | null>(null)

  const mine = (b: { poster: string; worker: string }) =>
    Boolean(address) && (b.poster.toLowerCase() === address?.toLowerCase() || b.worker.toLowerCase() === address?.toLowerCase())

  const shown = data.bounties.filter((b) => {
    if (view === 'open' && b.status !== STATUS.Open) return false
    if (view === 'mine' && !mine(b)) return false
    if (category !== null && b.category !== category) return false
    return true
  })

  return (
    <div className="space-y-4">
      <button
        onClick={onPost}
        disabled={!isConnected || !data.isHolder}
        className="flex min-h-12 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold text-white transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-40"
        style={{ background: 'var(--accent)' }}
      >
        <Plus className="size-4" />
        {!isConnected ? 'Connect a wallet to post' : data.isHolder === false ? 'Agent ID required to post' : 'Post a bounty'}
      </button>

      <div className="flex gap-2 overflow-x-auto pb-1">
        {(['open', 'mine', 'all'] as const).map((v) => (
          <Chip key={v} active={view === v} onClick={() => setView(v)}>
            {v === 'open' ? 'Open' : v === 'mine' ? 'Mine' : 'All'}
          </Chip>
        ))}
        <span className="mx-1 w-px shrink-0 self-stretch" style={{ background: 'var(--border)' }} />
        <Chip active={category === null} onClick={() => setCategory(null)}>
          Any type
        </Chip>
        {CATEGORIES.map((c) => (
          <Chip key={c.id} active={category === c.id} onClick={() => setCategory(c.id)}>
            {c.label}
          </Chip>
        ))}
      </div>

      <p className="px-1 text-xs tabular-nums" style={{ color: 'var(--muted)' }}>
        Showing {shown.length} {view === 'open' ? 'open' : view === 'mine' ? 'of your' : ''}{' '}
        {category === null ? '' : `${CATEGORIES[category]?.label ?? ''} `}
        {shown.length === 1 ? 'bounty' : 'bounties'}
        {view !== 'all' || category !== null ? ` (${data.bounties.length} total on the board)` : ''}
      </p>

      {data.loading && data.bounties.length === 0 ? (
        <div className="card h-28 animate-pulse rounded-3xl" />
      ) : shown.length === 0 ? (
        <div className="card rounded-3xl p-6 text-center text-sm" style={{ color: 'var(--muted)' }}>
          {data.bounties.length === 0
            ? 'No bounties have been posted yet. Be the first Agent ID holder to post one.'
            : 'No bounties match these filters. Try "All" or "Any type".'}
        </div>
      ) : (
        shown.map((b) => <BountyCard key={b.id.toString()} bounty={b} data={data} actions={actions} now={now} />)
      )}
    </div>
  )
}

function Chip({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      aria-pressed={active}
      className="min-h-11 shrink-0 rounded-xl px-4 text-xs font-semibold"
      style={
        active
          ? { background: 'var(--accent)', color: '#fff' }
          : { background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink-2)' }
      }
    >
      {children}
    </button>
  )
}
