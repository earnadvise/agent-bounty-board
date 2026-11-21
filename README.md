# Agent Bounty Board

A bounty board for Agent ID holders on BNB Chain. Holders post token-denominated bounties held in escrow, claim and complete each other's bounties, and check in daily. The contract has no owner and no fees.

Built with [Arc Studio](https://studio.arc.io)

## Features

- Post a bounty with a reward held in escrow
- Claim, submit work, approve or reject, and collect after a 7 day review window
- Cancel an unclaimed bounty for a full refund
- Daily check-in with a streak counter
- Bounty categories (Dev, Design, Research, Content, Community, Other) with filters
- Agent reputation: points, ranks from Rookie to Elite, and a leaderboard
- A personal agent card with a unique avatar and a share button
- Live totals for rewards paid, funds in escrow, and active agents
- Only wallets holding an Agent ID can post, claim or check in
- Plain disclosure of contract permissions and risks in the app

## Tech stack

React, Vite, TypeScript, Tailwind CSS, wagmi, viem, ConnectKit. Solidity 0.8.28 with Foundry and OpenZeppelin.

## Development

Prerequisites: [Bun](https://bun.sh) and [Foundry](https://getfoundry.sh).

```bash
bun install
bun run dev
```

Environment variables:

- `VITE_BOUNTY_BOARD_ADDRESS`: address of your deployed board contract on BNB Chain. Until it is set, the app shows a setup notice.
- `RPC_PROXY_BASE_URL`, `RPC_PROXY_TOKEN`, `RPC_PROXY_CHAINS`: optional outside Arc Studio, only used by backend tooling.

Test the contract:

```bash
forge test
```

Deployment and BscScan verification steps are in [DEPLOY.md](./DEPLOY.md).
