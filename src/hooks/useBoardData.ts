import { useMemo } from 'react'
import { erc20Abi, type Address } from 'viem'
import { useAccount, useReadContract, useReadContracts } from 'wagmi'
import { useNow } from '@/hooks/useNow'
import { boardAbi } from '@/lib/boardAbi'
import {
  AGENT_ID_ADDRESS,
  BOARD_ADDRESS,
  BOARD_CHAIN_ID,
  scoreOf,
  type Bounty,
  type BountyWithId,
  type Profile,
} from '@/lib/board'

const PAGE = 60n
const PROFILE_PAGE = 100n
const ZERO: Address = '0x0000000000000000000000000000000000000000'

const agentIdAbi = [
  {
    type: 'function',
    name: 'balanceOf',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
] as const

const EMPTY_PROFILE: Profile = {
  user: ZERO,
  posted: 0,
  completed: 0,
  earned: 0n,
  spent: 0n,
  streak: 0n,
  totalCheckIns: 0n,
  lastCheckInDay: 0n,
}

export function useBoardData() {
  const { address } = useAccount()
  const now = useNow()
  const user = address ?? ZERO
  const enabled = Boolean(BOARD_ADDRESS)
  const board = BOARD_ADDRESS ?? ZERO

  const core = useReadContracts({
    allowFailure: true,
    query: { enabled, refetchInterval: 8000 },
    contracts: [
      { address: board, abi: boardAbi, functionName: 'paymentToken', chainId: BOARD_CHAIN_ID },
      { address: board, abi: boardAbi, functionName: 'bountyCount', chainId: BOARD_CHAIN_ID },
      { address: board, abi: boardAbi, functionName: 'getProfile', args: [user], chainId: BOARD_CHAIN_ID },
      { address: AGENT_ID_ADDRESS, abi: agentIdAbi, functionName: 'balanceOf', args: [user], chainId: BOARD_CHAIN_ID },
      { address: board, abi: boardAbi, functionName: 'totalPaidOut', chainId: BOARD_CHAIN_ID },
      { address: board, abi: boardAbi, functionName: 'activeEscrow', chainId: BOARD_CHAIN_ID },
      { address: board, abi: boardAbi, functionName: 'participantCount', chainId: BOARD_CHAIN_ID },
    ],
  })

  const token = core.data?.[0]?.result
  const count = (core.data?.[1]?.result) ?? 0n
  const me = (core.data?.[2]?.result) ?? { ...EMPTY_PROFILE, user }
  const agentBalance = core.data?.[3]?.result
  const totalPaidOut = core.data?.[4]?.result
  const activeEscrow = core.data?.[5]?.result
  const participants = (core.data?.[6]?.result) ?? 0n

  const tokenReads = useReadContracts({
    allowFailure: true,
    query: { enabled: Boolean(token), refetchInterval: 8000 },
    contracts: token
      ? [
          { address: token, abi: erc20Abi, functionName: 'decimals', chainId: BOARD_CHAIN_ID },
          { address: token, abi: erc20Abi, functionName: 'symbol', chainId: BOARD_CHAIN_ID },
          { address: token, abi: erc20Abi, functionName: 'balanceOf', args: [user], chainId: BOARD_CHAIN_ID },
          { address: token, abi: erc20Abi, functionName: 'allowance', args: [user, board], chainId: BOARD_CHAIN_ID },
        ]
      : [],
  })

  const offset = count > PAGE ? count - PAGE : 0n
  const list = useReadContract({
    address: board,
    abi: boardAbi,
    functionName: 'getBounties',
    args: [offset, PAGE],
    chainId: BOARD_CHAIN_ID,
    query: { enabled: enabled && count > 0n, refetchInterval: 8000 },
  })

  const profileList = useReadContract({
    address: board,
    abi: boardAbi,
    functionName: 'getProfiles',
    args: [0n, PROFILE_PAGE],
    chainId: BOARD_CHAIN_ID,
    query: { enabled: enabled && participants > 0n, refetchInterval: 15000 },
  })

  const bounties = useMemo<BountyWithId[]>(() => {
    const rows = (list.data ?? []) as readonly Bounty[]
    return rows
      .map((b, i) => ({ ...b, id: offset + BigInt(i) }))
      .sort((a, b) => (a.id > b.id ? -1 : 1))
  }, [list.data, offset])

  const leaderboard = useMemo<Profile[]>(() => {
    const rows = [...((profileList.data ?? []) as readonly Profile[])]
    return rows.sort((a, b) => {
      const diff = scoreOf(b) - scoreOf(a)
      if (diff !== 0) return diff
      return a.earned === b.earned ? 0 : a.earned > b.earned ? -1 : 1
    })
  }, [profileList.data])

  const today = BigInt(Math.floor(now / 86_400))
  const checkedInToday = me.totalCheckIns > 0n && me.lastCheckInDay === today

  return {
    enabled,
    token,
    count,
    bounties,
    leaderboard,
    participants,
    totalPaidOut,
    activeEscrow,
    me,
    isHolder: agentBalance === undefined ? undefined : agentBalance > 0n,
    checkedInToday,
    decimals: tokenReads.data?.[0]?.result,
    symbol: tokenReads.data?.[1]?.result,
    tokenBalance: tokenReads.data?.[2]?.result,
    allowance: tokenReads.data?.[3]?.result,
    loading: core.isLoading || list.isLoading,
    refetch: async () => {
      await Promise.all([core.refetch(), tokenReads.refetch(), list.refetch(), profileList.refetch()])
    },
  }
}

export type BoardData = ReturnType<typeof useBoardData>
