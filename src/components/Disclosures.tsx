import { ExternalLink, Info } from 'lucide-react'
import { AGENT_ID_ADDRESS, BOARD_ADDRESS, BOARD_CHAIN_ID } from '@/lib/board'
import { buildAddressExplorerUrl } from '@/onchain-facts'

export function Disclosures() {
  return (
    <section className="card rounded-3xl p-5">
      <div className="mb-2 flex items-center gap-1.5">
        <Info className="size-4" style={{ color: 'var(--accent-hover)' }} />
        <h2 className="text-sm font-semibold" style={{ color: 'var(--ink)' }}>
          Contract permissions and risks
        </h2>
      </div>
      <ul className="space-y-1.5 text-xs leading-relaxed text-pretty" style={{ color: 'var(--ink-2)' }}>
        <li>
          Owner permissions: none. The contract has no owner, admin, pause, fee, upgrade or withdraw function.
        </li>
        <li>
          Funds move only when a poster approves work, a worker collects after the 7 day review window, or a poster
          cancels an unclaimed bounty.
        </li>
        <li>
          Approvals are for the exact reward you post, never unlimited. Every transaction asks you to confirm in your
          wallet.
        </li>
        <li>
          Bounties are payments between participants. Nothing here is investment advice or a promise of returns, and
          onchain transactions cannot be reversed.
        </li>
      </ul>
      <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs font-semibold" style={{ color: 'var(--accent-hover)' }}>
        {BOARD_ADDRESS && (
          <a
            className="inline-flex items-center gap-1"
            href={buildAddressExplorerUrl(BOARD_CHAIN_ID, BOARD_ADDRESS)}
            target="_blank"
            rel="noopener noreferrer"
          >
            Board contract <ExternalLink className="size-3" />
          </a>
        )}
        <a
          className="inline-flex items-center gap-1"
          href={buildAddressExplorerUrl(BOARD_CHAIN_ID, AGENT_ID_ADDRESS)}
          target="_blank"
          rel="noopener noreferrer"
        >
          Agent ID contract <ExternalLink className="size-3" />
        </a>
      </div>
    </section>
  )
}
