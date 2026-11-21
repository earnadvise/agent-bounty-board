import { ConnectKitButton } from 'connectkit'
import { useAccount, useSwitchChain } from 'wagmi'
import { BadgeCheck } from 'lucide-react'
import { BOARD_CHAIN_ID, shortAddress } from '@/lib/board'

export function Header() {
  const { isConnected, chainId } = useAccount()
  const { switchChain, isPending } = useSwitchChain()
  const wrongChain = isConnected && chainId !== BOARD_CHAIN_ID

  return (
    <header className="flex items-center justify-between gap-3 py-5">
      <div className="flex items-center gap-2.5">
        <div className="flex size-9 items-center justify-center rounded-xl" style={{ background: 'var(--accent)' }}>
          <BadgeCheck className="size-5 text-white" />
        </div>
        <div>
          <h1 className="display text-lg font-bold leading-none" style={{ color: 'var(--ink)' }}>
            Agent Bounty Board
          </h1>
          <p className="mt-1 text-xs" style={{ color: 'var(--muted)' }}>
            USDC bounties for Agent ID holders
          </p>
        </div>
      </div>

      <ConnectKitButton.Custom>
        {({ isConnected: connected, show, address }) =>
          wrongChain ? (
            <button
              onClick={() => switchChain({ chainId: BOARD_CHAIN_ID })}
              disabled={isPending}
              className="min-h-11 rounded-xl px-4 text-sm font-semibold text-white disabled:opacity-50"
              style={{ background: 'var(--danger)' }}
            >
              Switch to BNB Chain
            </button>
          ) : (
            <button
              onClick={show}
              className="min-h-11 rounded-xl px-4 text-sm font-semibold"
              style={
                connected
                  ? { background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink)' }
                  : { background: 'var(--accent)', color: '#fff' }
              }
            >
              {connected && address ? <span className="mono text-xs">{shortAddress(address)}</span> : 'Connect wallet'}
            </button>
          )
        }
      </ConnectKitButton.Custom>
    </header>
  )
}
