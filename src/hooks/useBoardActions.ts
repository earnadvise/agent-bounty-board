import { useCallback, useState } from 'react'
import { erc20Abi, type Address, type Hash } from 'viem'
import { useAccount, usePublicClient, useSwitchChain, useWriteContract } from 'wagmi'
import { toast } from 'sonner'
import { boardAbi } from '@/lib/boardAbi'
import { BOARD_ADDRESS, BOARD_CHAIN_ID, parseOnchainError } from '@/lib/board'

type PostArgs = {
  title: string
  details: string
  reward: bigint
  claimWindow: number
  category: number
  token: Address
  allowance: bigint
}

/**
 * Every write the board supports. Approvals are always for the exact reward
 * being escrowed, never unlimited.
 */
export function useBoardActions(onSuccess: () => Promise<void>) {
  const { chainId } = useAccount()
  const { switchChainAsync } = useSwitchChain()
  const { writeContractAsync } = useWriteContract()
  const publicClient = usePublicClient({ chainId: BOARD_CHAIN_ID })
  const [busy, setBusy] = useState<string | null>(null)
  const [lastHash, setLastHash] = useState<Hash | null>(null)

  const exec = useCallback(
    async (key: string, label: string, run: (board: Address) => Promise<Hash[]>): Promise<boolean> => {
      if (!BOARD_ADDRESS || !publicClient) return false
      setBusy(key)
      try {
        if (chainId !== BOARD_CHAIN_ID) await switchChainAsync({ chainId: BOARD_CHAIN_ID })
        const hashes = await run(BOARD_ADDRESS)
        const last = hashes[hashes.length - 1]
        if (last) setLastHash(last)
        toast.success(`${label} confirmed`)
        await onSuccess()
        return true
      } catch (error) {
        const parsed = parseOnchainError(error)
        if (parsed.cancelled) toast(parsed.message)
        else toast.error(parsed.message)
        return false
      } finally {
        setBusy(null)
      }
    },
    [chainId, onSuccess, publicClient, switchChainAsync],
  )

  const confirm = useCallback(
    async (hash: Hash) => {
      if (!publicClient) throw new Error('network')
      const receipt = await publicClient.waitForTransactionReceipt({ hash })
      if (receipt.status !== 'success') throw new Error('reverted')
      return hash
    },
    [publicClient],
  )

  const checkIn = () =>
    exec('checkin', 'Check-in', async (board) => [
      await confirm(
        await writeContractAsync({ address: board, abi: boardAbi, functionName: 'checkIn', chainId: BOARD_CHAIN_ID }),
      ),
    ])

  const post = (a: PostArgs) =>
    exec('post', 'Bounty posted', async (board) => {
      const hashes: Hash[] = []
      if (a.allowance < a.reward) {
        hashes.push(
          await confirm(
            await writeContractAsync({
              address: a.token,
              abi: erc20Abi,
              functionName: 'approve',
              args: [board, a.reward],
              chainId: BOARD_CHAIN_ID,
            }),
          ),
        )
      }
      hashes.push(
        await confirm(
          await writeContractAsync({
            address: board,
            abi: boardAbi,
            functionName: 'postBounty',
            args: [a.title, a.details, a.reward, BigInt(a.claimWindow), a.category],
            chainId: BOARD_CHAIN_ID,
          }),
        ),
      )
      return hashes
    })

  const byId = (
    fn: 'claimBounty' | 'releaseClaim' | 'approveWork' | 'rejectWork' | 'claimAfterReviewWindow' | 'cancelBounty',
    label: string,
  ) =>
    (id: bigint) =>
      exec(`${fn}-${id}`, label, async (board) => [
        await confirm(
          await writeContractAsync({ address: board, abi: boardAbi, functionName: fn, args: [id], chainId: BOARD_CHAIN_ID }),
        ),
      ])

  const submit = (id: bigint, proof: string) =>
    exec(`submitWork-${id}`, 'Work submitted', async (board) => [
      await confirm(
        await writeContractAsync({
          address: board,
          abi: boardAbi,
          functionName: 'submitWork',
          args: [id, proof],
          chainId: BOARD_CHAIN_ID,
        }),
      ),
    ])

  return {
    busy,
    lastHash,
    checkIn,
    post,
    submit,
    claim: byId('claimBounty', 'Bounty claimed'),
    release: byId('releaseClaim', 'Claim released'),
    approve: byId('approveWork', 'Payment sent'),
    reject: byId('rejectWork', 'Work rejected'),
    collect: byId('claimAfterReviewWindow', 'Reward collected'),
    cancel: byId('cancelBounty', 'Bounty cancelled'),
  }
}

export type BoardActions = ReturnType<typeof useBoardActions>
