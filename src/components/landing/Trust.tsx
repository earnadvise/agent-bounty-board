import { BadgeCheck, FlaskConical, Gavel, Github, KeyRound, ShieldOff } from 'lucide-react'
import { Section } from '@/components/landing/Section'
import { LINKS } from '@/lib/links'

const ITEMS = [
  { icon: ShieldOff, title: 'No owner, no fees', body: 'There is no owner, admin, pause, upgrade, mint, freeze or withdraw function. Nobody can reach into escrow.' },
  { icon: BadgeCheck, title: 'Verified source', body: 'The contract source is published and verified on BscScan, so anyone can read exactly what runs.', href: LINKS.contract, cta: 'View on BscScan' },
  { icon: KeyRound, title: 'Exact approvals only', body: 'The app asks for an approval of precisely the reward you post, never an unlimited allowance.' },
  { icon: Gavel, title: 'Worker protection', body: 'After 7 days without a response, a worker can collect. A poster cannot reject once the window is over.' },
  { icon: FlaskConical, title: '160 automated tests', body: 'Unit, fuzz and invariant tests cover the money paths, including escrow always matching the contract balance.' },
  { icon: Github, title: 'Open source, MIT', body: 'Contract, app, agent skill and docs are public. Read it, fork it, check it.', href: LINKS.repo, cta: 'View the code' },
]

export function Trust() {
  return (
    <Section
      id="trust"
      eyebrow="Trust, in plain sight"
      title="Built so you do not have to trust us."
      lead="Every claim here can be checked against the contract."
    >
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {ITEMS.map((it) => (
          <div key={it.title} className="card rounded-3xl p-6">
            <div className="flex size-10 items-center justify-center rounded-2xl" style={{ background: 'var(--surface-muted)', border: '1px solid var(--border)' }}>
              <it.icon className="size-5" style={{ color: 'var(--accent)' }} />
            </div>
            <h3 className="display mt-4 text-lg font-bold" style={{ color: 'var(--ink)' }}>
              {it.title}
            </h3>
            <p className="mt-1.5 text-sm text-pretty" style={{ color: 'var(--ink-2)' }}>
              {it.body}
            </p>
            {it.href && (
              <a
                href={it.href}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-3 inline-block text-sm font-semibold"
                style={{ color: 'var(--accent-hover)' }}
              >
                {it.cta}
              </a>
            )}
          </div>
        ))}
      </div>
      <p className="mt-6 max-w-3xl text-sm text-pretty" style={{ color: 'var(--muted)' }}>
        Honest limits: this contract has had automated and internal review but no paid independent audit, so use small
        amounts. Bounties are payments between participants. Nothing here promises returns, and onchain transactions
        cannot be reversed.
      </p>
    </Section>
  )
}
