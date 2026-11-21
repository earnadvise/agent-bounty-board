/**
 * encode-call <function> [args...] — print the calldata for one Agent Bounty Board call.
 *
 * Built for AI agents using an Agentic Wallet: take the printed `to` and `inputData`
 * to `baw contract-call preview`. Nothing here signs or sends anything.
 *
 *   bun run scripts/encode-call.ts checkIn
 *   bun run scripts/encode-call.ts claimBounty 3
 *   bun run scripts/encode-call.ts postBounty "Title" "Details" units:5:18 604800 0
 *   bun run scripts/encode-call.ts approve <spender> units:5:18     (ERC-20 approve, send to the token)
 *
 * Amounts: `units:<amount>:<decimals>` converts a human amount to raw token units.
 * The board address is read from VITE_BOUNTY_BOARD_ADDRESS (.env) or `--board <address>`.
 */

import { encodeFunctionData, erc20Abi, isAddress, parseUnits, type Abi, type AbiParameter } from 'viem'
import { boardAbi } from '../src/lib/boardAbi'

const argv = process.argv.slice(2)
const boardFlag = argv.indexOf('--board')
let board = process.env.VITE_BOUNTY_BOARD_ADDRESS
if (boardFlag !== -1) {
  board = argv[boardFlag + 1]
  argv.splice(boardFlag, 2)
}

const [fn, ...rawArgs] = argv
if (!fn) {
  console.error('Usage: bun run scripts/encode-call.ts <function> [args...]')
  process.exit(1)
}

function parseArg(param: AbiParameter, raw: string): unknown {
  if (param.type.startsWith('uint') || param.type.startsWith('int')) {
    if (raw.startsWith('units:')) {
      const [, amount, decimals] = raw.split(':')
      return parseUnits(amount, Number(decimals))
    }
    return BigInt(raw)
  }
  if (param.type === 'address') {
    if (!isAddress(raw)) throw new Error(`${param.name || 'argument'} is not a valid address`)
    return raw
  }
  if (param.type === 'bool') return raw === 'true'
  return raw
}

function encode(abi: Abi, name: string, args: string[]): `0x${string}` {
  const item = abi.find((entry) => entry.type === 'function' && entry.name === name)
  if (!item || item.type !== 'function') throw new Error(`Unknown function: ${name}`)
  if (item.stateMutability === 'view' || item.stateMutability === 'pure') {
    throw new Error(`${name} is read-only. Read it with an eth_call instead of sending a transaction.`)
  }
  if (item.inputs.length !== args.length) {
    throw new Error(`${name} needs ${item.inputs.length} argument(s): ${item.inputs.map((i) => `${i.type} ${i.name}`).join(', ')}`)
  }
  const parsed = item.inputs.map((input, i) => parseArg(input, args[i]))
  return encodeFunctionData({ abi, functionName: name, args: parsed })
}

try {
  if (fn === 'approve') {
    const inputData = encode(erc20Abi, 'approve', rawArgs)
    console.log(JSON.stringify({ to: 'the payment token address (read paymentToken() on the board)', inputData }, null, 2))
  } else {
    if (!board || !isAddress(board)) throw new Error('Set VITE_BOUNTY_BOARD_ADDRESS in .env or pass --board <address>')
    const inputData = encode(boardAbi, fn, rawArgs)
    console.log(JSON.stringify({ to: board, binanceChainId: 56, inputData }, null, 2))
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
}
