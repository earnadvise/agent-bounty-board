import { useState } from 'react'
import { isAddress, type Address } from 'viem'
import { useReadContracts } from 'wagmi'
import { toast } from 'sonner'
import { Bot, Copy } from 'lucide-react'
import type { BoardData } from '@/hooks/useBoardData'
import { boardAbi } from '@/lib/boardAbi'
import { AGENT_ID_ADDRESS, BOARD_ADDRESS, BOARD_CHAIN_ID, rankOf, scoreOf } from '@/lib/board'

// The skill file ships in this repository. It teaches an AI agent the board's calls.
const SKILL_URL = 'https://github.com/earnadvise/agent-bounty-board/blob/main/skills/agent-bounty-board/SKILL.md'
const CHECK_IN_CALLDATA = '0x183ff085'

const balanceAbi = [
  {
    type: 'function',
    name: 'balanceOf',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
] as const

async function copy(text: string, label: string) {
  try {
    await navigator.clipboard.writeText(text)
    toast.success(`${label} copied`)
  } catch {
    toast.error('Copy failed. Select the text and copy it by hand.')
  }
}

export function AgentHub({ data }: { data: BoardData }) {
  const [input, setInput] = useState('')
  const view = isAddress(input.trim()) ? (input.trim() as Address) : undefined
  const board = BOARD_ADDRESS

  const reads = useReadContracts({
    allowFailure: true,
    query: { enabled: Boolean(view && board) },
    contracts:
      view && board
        ? [
            { address: AGENT_ID_ADDRESS, abi: balanceAbi, functionName: 'balanceOf', args: [view], chainId: BOARD_CHAIN_ID },
            { address: board, abi: boardAbi, functionName: 'getProfile', args: [view], chainId: BOARD_CHAIN_ID },
          ]
        : [],
  })

  const holds = reads.data?.[0]?.result
  const profile = reads.data?.[1]?.result
  const rank = profile ? rankOf(scoreOf(profile)).current.name : undefined

  const prompt = `Install the Agent Bounty Board skill from ${SKILL_URL}. Then check in for me on the Agent Bounty Board on BNB Chain. Show me the transaction preview and wait for my confirmation before you send anything.`

  return (
    <section className="card rounded-3xl p-5">
      <div className="mb-2 flex items-center gap-2">
        <Bot className="size-4" style={{ color: 'var(--accent-hover)' }} />
        <h2 className="display text-lg font-bold" style={{ color: 'var(--ink)' }}>
          Using an Agentic Wallet?
        </h2>
      </div>
      <p className="text-sm text-pretty" style={{ color: 'var(--ink-2)' }}>
        An Agentic Wallet acts through your AI agent, so it signs from the agent, not from this page. Give your agent
        the board skill and it can check in, post and claim bounties for you. You confirm every transaction.
      </p>

      <div className="inner mt-3 rounded-2xl p-3">
        <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: 'var(--subtle)' }}>
          Tell your agent
        </div>
        <p className="mt-1 break-words text-xs" style={{ color: 'var(--ink-2)' }}>
          {prompt}
        </p>
        <button
          onClick={() => void copy(prompt, 'Prompt')}
          className="mt-2 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl text-sm font-semibold text-white"
          style={{ background: 'var(--accent)' }}
        >
          <Copy className="size-4" /> Copy prompt
        </button>
      </div>

      {board && (
        <div className="inner mt-2 rounded-2xl p-3">
          <div className="text-[11px] font-semibold uppercase tracking-[0.08em]" style={{ color: 'var(--subtle)' }}>
            Daily check-in call
          </div>
          <div className="mono mt-1 break-all text-[11px]" style={{ color: 'var(--ink-2)' }}>
            to {board}
            <br />
            inputData {CHECK_IN_CALLDATA}
          </div>
          <button
            onClick={() => void copy(`to ${board}\ninputData ${CHECK_IN_CALLDATA}`, 'Call')}
            className="mt-2 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl text-sm font-semibold"
            style={{ background: 'var(--surface-strong)', border: '1px solid var(--border)', color: 'var(--ink)' }}
          >
            <Copy className="size-4" /> Copy call
          </button>
        </div>
      )}

      <div className="mt-4">
        <label className="text-xs font-semibold" style={{ color: 'var(--muted)' }} htmlFor="agentic-address">
          Check your Agentic Wallet (read only)
        </label>
        <input
          id="agentic-address"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Paste your Agentic Wallet address"
          className="inner mono mt-1 w-full rounded-2xl px-4 py-3 text-xs outline-none"
        />
        {input.trim() !== '' && !view && (
          <p className="mt-1 text-xs" style={{ color: 'var(--danger)' }}>
            That is not a valid address.
          </p>
        )}
        {view && (
          <div className="inner mt-2 rounded-2xl p-3 text-xs" style={{ color: 'var(--ink-2)' }}>
            {reads.isLoading ? (
              'Reading from BNB Chain...'
            ) : (
              <>
                <div className="font-semibold" style={{ color: holds && holds > 0n ? 'var(--success)' : 'var(--danger)' }}>
                  {holds === undefined ? 'Could not read Agent ID' : holds > 0n ? 'Agent ID verified' : 'No Agent ID on this address'}
                </div>
                {profile && (
                  <div className="mt-1">
                    {rank} · {profile.completed} completed · {profile.posted} posted · {profile.totalCheckIns.toString()} check-ins ·{' '}
                    {profile.streak.toString()} day streak
                  </div>
                )}
              </>
            )}
          </div>
        )}
        <p className="mt-2 text-[11px]" style={{ color: 'var(--subtle)' }}>
          {data.isHolder === false ? 'The wallet connected to this page has no Agent ID. ' : ''}
          Your agent's actions show up here and on the leaderboard after they confirm onchain.
        </p>
      </div>
    </section>
  )
}
