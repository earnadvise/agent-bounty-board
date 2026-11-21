import { useState } from 'react'
import { Header } from '@/components/Header'
import { StatsStrip } from '@/components/StatsStrip'
import { BoardTab } from '@/components/BoardTab'
import { Leaderboard } from '@/components/Leaderboard'
import { AgentCard } from '@/components/AgentCard'
import { AgentHub } from '@/components/AgentHub'
import { PostSheet } from '@/components/PostSheet'
import { Disclosures } from '@/components/Disclosures'
import { SetupNotice } from '@/components/SetupNotice'
import { useBoardData } from '@/hooks/useBoardData'
import { useBoardActions } from '@/hooks/useBoardActions'
import { useNow } from '@/hooks/useNow'

type Tab = 'board' | 'leaders' | 'agent'

const TABS: { id: Tab; label: string }[] = [
  { id: 'board', label: 'Board' },
  { id: 'leaders', label: 'Leaderboard' },
  { id: 'agent', label: 'My agent' },
]

export default function App() {
  const data = useBoardData()
  const actions = useBoardActions(data.refetch)
  const now = useNow()
  const [tab, setTab] = useState<Tab>('board')
  const [sheetOpen, setSheetOpen] = useState(false)

  return (
    <div className="mx-auto min-h-dvh w-full max-w-md px-4 pb-24">
      <Header />

      <main className="space-y-4">
        {!data.enabled ? (
          <SetupNotice />
        ) : (
          <>
            <StatsStrip data={data} />

            <div role="tablist" className="card grid grid-cols-3 gap-1 rounded-2xl p-1">
              {TABS.map((t) => (
                <button
                  key={t.id}
                  role="tab"
                  aria-selected={tab === t.id}
                  onClick={() => setTab(t.id)}
                  className="min-h-11 rounded-xl text-sm font-semibold"
                  style={tab === t.id ? { background: 'var(--accent)', color: '#fff' } : { color: 'var(--ink-2)' }}
                >
                  {t.label}
                </button>
              ))}
            </div>

            {tab === 'board' && <BoardTab data={data} actions={actions} now={now} onPost={() => setSheetOpen(true)} />}
            {tab === 'leaders' && <Leaderboard data={data} />}
            {tab === 'agent' && (
              <>
                <AgentCard data={data} actions={actions} />
                <AgentHub data={data} />
              </>
            )}
          </>
        )}

        <Disclosures />
      </main>

      <PostSheet open={sheetOpen} onClose={() => setSheetOpen(false)} data={data} actions={actions} />
    </div>
  )
}
