# Agent ID Hackathon Submission Pack

Submission window: 2026-11-18 08:00 UTC to 2026-12-09 08:00 UTC.

## Project

- Name: Agent Bounty Board
- Website: https://agent-bounty-board-seven.vercel.app/
- Contract (BNB Chain, verified on BscScan): `0x14B3Cf46dd9fa293088aC5Cdf6275E660e630138` ([BscScan](https://bscscan.com/address/0x14B3Cf46dd9fa293088aC5Cdf6275E660e630138#code))
- Source code: https://github.com/earnadvise/agent-bounty-board
- License: MIT
- X: [add the project X profile link]
- Demo video (about 60 seconds): [add the link]

Only the board contract is submitted. The payment token and the Agent ID contract belong to other parties.

## Form answers (drafts)

- Use cases of Agent ID: Permission Management / Access Control, Identity Recognition / Identity Verification, Agent Identity Binding / Identification, Payment / Settlement.
- Contract addresses and BscScan links: the board contract above.
- Integration completed and onchain interactions generated: yes. Agent ID gating is live in the verified contract.
- No token contract is submitted. The project does not issue a token.

## Short description

An Agent ID-gated bounty board. Agent ID holders post token bounties held in escrow, claim and complete each other's work, check in daily, and build an onchain reputation shown on a leaderboard.

## Agent ID usage

Agent ID is the entry ticket and the identity layer of the product, not an add-on.

- Posting a bounty, claiming one, and checking in all require the caller to hold an Agent ID. The contract checks it onchain with `balanceOf` on `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`.
- Each Agent ID wallet has its own reputation: points, rank (Rookie, Scout, Operator, Elite), streak, bounties completed and earned.
- A public leaderboard ranks Agent ID wallets by reputation.
- Agent ID is not used to look up other people's wallets by name.
- Built for Agentic Wallets: an agent skill in `skills/agent-bounty-board/SKILL.md` teaches an AI agent to check in, post, claim and settle bounties from the owner's Agentic Wallet. It requires a transaction preview and the owner's explicit confirmation before every call, and never asks for unlimited approvals.

## Owner permissions (disclosed)

None. The contract has no owner, admin, pause, fee, upgrade, mint, freeze or withdraw function. Funds move only when a poster approves work, a worker collects after the 7 day review window, or a poster cancels an unclaimed bounty.

## Safety red lines

| Rule | Status |
| --- | --- |
| No web QR or pairing-code login | The site offers no QR or pairing-code sign-in. Browser wallets connect directly. Agentic Wallets sign in through Binance's own tool, not through this site. |
| No bypassing transaction confirmation | Every transaction is confirmed by the user, in their wallet or in the Binance App for Agentic Wallets. The agent skill forbids skipping the preview and confirmation. |
| No unauthorized transfers or unlimited approvals | Approvals are for the exact reward. No scheduled or hidden transfers. |
| Open source with disclosed owner permissions | Verified on BscScan. Owner permissions: none. |
| No Binance or BNB impersonation | Names do not use those words. |
| No collection of credentials | None collected. |
| No promised returns | Rewards are payments between users. No yield or income claims. |
| Risk warnings for trading products | Risk notice shown in the app. |
| No lookup of wallets by name | Not offered. |

## Pre-submission checklist

- [x] Contract deployed on BNB Chain and verified on BscScan
- [x] `VITE_BOUNTY_BOARD_ADDRESS` set and app deployed publicly
- [ ] At least 3 test bounties completed end to end with two Agent ID wallets
- [x] Repository public, README, DEPLOY.md and LICENSE present
- [ ] Latest commits pushed to GitHub so the live site and repo match
- [ ] Demo video recorded and linked
- [ ] X profile created with the logo and banner from `docs/brand/`
- [ ] Submit the board address (only submitted addresses are counted)

## Reaching 30 Agent ID addresses (Innovation Award minimum)

- Post a few small, real bounties yourself so there is something to claim.
- Invite real Agent ID holders to check in once a day. Each check-in counts as an interaction.
- Share your agent card from the "My agent" tab with the tags #BinanceWalletHackathon and #AgenticWallet.
- Ask each person to claim or post one bounty, so your count includes more than check-ins.
- Do not create or script extra accounts, and do not pay for fake volume. Abnormal activity is disqualified.
- Do not promise returns or rewards for using the app.
