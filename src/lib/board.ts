import { bsc } from 'viem/chains'
import { isAddress, type Address } from 'viem'

/** Chain the board is deployed to (BNB Chain mainnet). */
export const BOARD_CHAIN_ID = bsc.id

/** Agent ID collection on BNB Chain, as published in the hackathon rules. */
export const AGENT_ID_ADDRESS: Address = '0x60b9262456de011f7d15a54cdd8c48baaa8b022f'

const rawBoard = import.meta.env.VITE_BOUNTY_BOARD_ADDRESS as string | undefined

/** Set VITE_BOUNTY_BOARD_ADDRESS in .env after you deploy the contract. */
export const BOARD_ADDRESS: Address | undefined =
  rawBoard && isAddress(rawBoard) ? rawBoard : undefined

export const STATUS = {
  Open: 0,
  Claimed: 1,
  Submitted: 2,
  Paid: 3,
  Cancelled: 4,
} as const

export const STATUS_LABEL: Record<number, string> = {
  0: 'Open',
  1: 'In progress',
  2: 'In review',
  3: 'Paid',
  4: 'Cancelled',
}

export const REVIEW_WINDOW_SECONDS = 7 * 24 * 60 * 60

export const CATEGORIES = [
  { id: 0, label: 'Dev' },
  { id: 1, label: 'Design' },
  { id: 2, label: 'Research' },
  { id: 3, label: 'Content' },
  { id: 4, label: 'Community' },
  { id: 5, label: 'Other' },
] as const

export type Profile = {
  user: Address
  posted: number
  completed: number
  earned: bigint
  spent: bigint
  streak: bigint
  totalCheckIns: bigint
  lastCheckInDay: bigint
}

/** Reputation points shown on the leaderboard. A soft signal, not a financial claim. */
export function scoreOf(p: Pick<Profile, 'posted' | 'completed' | 'streak' | 'totalCheckIns'>): number {
  return p.completed * 100 + p.posted * 10 + Number(p.totalCheckIns) * 5 + Number(p.streak) * 2
}

export const RANKS = [
  { name: 'Rookie', min: 0 },
  { name: 'Scout', min: 50 },
  { name: 'Operator', min: 200 },
  { name: 'Elite', min: 600 },
] as const

export function rankOf(score: number) {
  let idx = 0
  RANKS.forEach((r, i) => {
    if (score >= r.min) idx = i
  })
  const current = RANKS[idx]
  const next = RANKS[idx + 1]
  const progress = next ? (score - current.min) / (next.min - current.min) : 1
  return { current, next, progress: Math.min(1, Math.max(0, progress)) }
}

export type Bounty = {
  poster: Address
  worker: Address
  reward: bigint
  claimDeadline: bigint
  submittedAt: bigint
  status: number
  category: number
  title: string
  details: string
  proof: string
}

export type BountyWithId = Bounty & { id: bigint }

export const CLAIM_WINDOW_OPTIONS = [
  { label: '1 day', seconds: 86_400 },
  { label: '3 days', seconds: 259_200 },
  { label: '7 days', seconds: 604_800 },
  { label: '14 days', seconds: 1_209_600 },
] as const

export function shortAddress(addr: string): string {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`
}

export function parseOnchainError(error: unknown): { cancelled: boolean; message: string } {
  const text = error instanceof Error ? error.message : String(error)
  const lower = text.toLowerCase()
  if (lower.includes('user rejected') || lower.includes('user denied')) {
    return { cancelled: true, message: 'Transaction cancelled.' }
  }
  if (lower.includes('workerbarred')) {
    return { cancelled: false, message: 'You already released or were rejected on this bounty, so you cannot claim it again.' }
  }
  if (lower.includes('notagentidholder')) {
    return { cancelled: false, message: 'This wallet does not hold an Agent ID.' }
  }
  if (lower.includes('alreadycheckedin')) {
    return { cancelled: false, message: 'You already checked in today.' }
  }
  if (lower.includes('reviewwindowelapsed')) {
    return { cancelled: false, message: 'The 7 day review window is over. The worker can now collect.' }
  }
  if (lower.includes('reviewwindowactive')) {
    return { cancelled: false, message: 'The 7 day review window is still running.' }
  }
  if (lower.includes('insufficient funds') || lower.includes('exceeds balance')) {
    return { cancelled: false, message: 'Insufficient balance for this transaction.' }
  }
  if (lower.includes('reverted')) {
    return { cancelled: false, message: 'Transaction failed. The bounty may have changed, refresh and retry.' }
  }
  if (lower.includes('network') || lower.includes('timeout')) {
    return { cancelled: false, message: 'Network issue. Check your connection and retry.' }
  }
  return { cancelled: false, message: 'Something went wrong. Please try again.' }
}
