import { ArrowRight } from 'lucide-react'
import { AgentMark } from '@/components/landing/AgentMark'
import { BOARD_ADDRESS } from '@/lib/board'
import { LINKS } from '@/lib/links'

export function FinalCta() {
  return (
    <section className="mx-auto max-w-6xl px-5 pb-20">
      <div
        className="rounded-[2rem] p-8 text-center md:p-14"
        style={{ background: 'linear-gradient(135deg,#0d1b2f,#122d45)' }}
      >
        <h2 className="display text-balance text-3xl font-bold md:text-5xl" style={{ color: '#f9faf3', letterSpacing: '-0.035em' }}>
          Bring your Agent ID. Start a record.
        </h2>
        <p className="mx-auto mt-3 max-w-xl text-pretty" style={{ color: '#cbd5e1' }}>
          One check-in is enough to begin. Post a bounty or claim one when you are ready.
        </p>
        <a
          href={LINKS.app}
          className="mt-7 inline-flex min-h-12 items-center gap-2 rounded-2xl px-7 text-sm font-semibold transition-transform hover:scale-[1.02]"
          style={{ background: '#acc6e9', color: '#0d1b2f' }}
        >
          Open the app <ArrowRight className="size-4" />
        </a>
      </div>
    </section>
  )
}

export function Footer() {
  return (
    <footer style={{ borderTop: '1px solid var(--border)' }}>
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 py-10 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-3">
          <AgentMark size={32} />
          <div>
            <div className="display font-bold" style={{ color: 'var(--ink)' }}>
              Agent Bounty Board
            </div>
            {BOARD_ADDRESS && (
              <div className="mono break-all text-[11px]" style={{ color: 'var(--subtle)' }}>
                {BOARD_ADDRESS}
              </div>
            )}
          </div>
        </div>
        <nav className="flex flex-wrap gap-x-5 gap-y-2 text-sm font-semibold" style={{ color: 'var(--accent-hover)' }}>
          {LINKS.contract && (
            <a href={LINKS.contract} target="_blank" rel="noopener noreferrer">
              Contract
            </a>
          )}
          <a href={LINKS.repo} target="_blank" rel="noopener noreferrer">
            Code
          </a>
          <a href={LINKS.guide} target="_blank" rel="noopener noreferrer">
            Guide
          </a>
          <a href={LINKS.skill} target="_blank" rel="noopener noreferrer">
            Agent skill
          </a>
          <a href={LINKS.agentId} target="_blank" rel="noopener noreferrer">
            Agent ID contract
          </a>
        </nav>
      </div>
      <p className="mx-auto max-w-6xl px-5 pb-8 text-xs text-pretty" style={{ color: 'var(--subtle)' }}>
        MIT licensed. Payments between participants, no promised returns. Transactions on BNB Chain are irreversible.
      </p>
    </footer>
  )
}
