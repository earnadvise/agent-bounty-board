/**
 * wagmi configuration: BNB Chain only.
 */

import { http, createConfig } from 'wagmi'
import { bsc } from 'viem/chains'
import { injected } from 'wagmi/connectors'
import { requireChain } from './onchain-facts'

// BNB Chain RPC comes from the onchain facts registry, never typed by hand
const bscRpc = requireChain(bsc.id).rpcUrls[0]

export const config = createConfig({
  chains: [bsc],
  connectors: [injected()],
  transports: {
    [bsc.id]: http(bscRpc),
  },
})
