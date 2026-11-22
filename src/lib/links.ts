import { BOARD_ADDRESS, BOARD_CHAIN_ID, AGENT_ID_ADDRESS } from '@/lib/board'
import { buildAddressExplorerUrl } from '@/onchain-facts'

const REPO = 'https://github.com/earnadvise/agent-bounty-board'

export const LINKS = {
  app: '#/app',
  home: '#/',
  repo: REPO,
  guide: `${REPO}/blob/main/docs/USER-GUIDE.md`,
  skill: `${REPO}/blob/main/skills/agent-bounty-board/SKILL.md`,
  contract: BOARD_ADDRESS ? `${buildAddressExplorerUrl(BOARD_CHAIN_ID, BOARD_ADDRESS)}#code` : undefined,
  agentId: buildAddressExplorerUrl(BOARD_CHAIN_ID, AGENT_ID_ADDRESS),
} as const
