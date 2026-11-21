# Agent ID Hackathon Submission Pack

Fill in the bracketed items after you deploy. Submission window: 2026-11-18 08:00 UTC to 2026-12-09 08:00 UTC.

## Project

- Name: Agent Bounty Board
- Website: [your deployed app URL]
- Contract (BNB Chain, verified on BscScan): [board address]
- Source code: [public repository URL]

## Short description

An Agent ID-gated bounty board. Agent ID holders post token bounties held in escrow, claim and complete each other's work, check in daily, and build an onchain reputation shown on a leaderboard.

## Agent ID usage

Agent ID is the entry ticket and the identity layer of the product, not an add-on.

- Posting a bounty, claiming one, and checking in all require the caller to hold an Agent ID. The contract checks it onchain with `balanceOf` on `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`.
- Each Agent ID wallet has its own reputation: points, rank (Rookie, Scout, Operator, Elite), streak, bounties completed and earned.
- A public leaderboard ranks Agent ID wallets by reputation.
- Agent ID is not used to look up other people's wallets by name.

## Owner permissions (disclosed)

None. The contract has no owner, admin, pause, fee, upgrade, mint, freeze or withdraw function. Funds move only when a poster approves work, a worker collects after the 7 day review window, or a poster cancels an unclaimed bounty.

## Safety red lines

| Rule | Status |
| --- | --- |
| No web QR or pairing-code login | No login of that kind. Wallet connection only. |
| No bypassing transaction confirmation | Every transaction is signed in the user's wallet. |
| No unauthorized transfers or unlimited approvals | Approvals are for the exact reward. No scheduled or hidden transfers. |
| Open source with disclosed owner permissions | Verified on BscScan. Owner permissions: none. |
| No Binance or BNB impersonation | Names do not use those words. |
| No collection of credentials | None collected. |
| No promised returns | Rewards are payments between users. No yield or income claims. |
| Risk warnings for trading products | Risk notice shown in the app. |
| No lookup of wallets by name | Not offered. |

## Pre-submission checklist

- [ ] Contract deployed on BNB Chain and verified on BscScan
- [ ] `VITE_BOUNTY_BOARD_ADDRESS` set and app deployed publicly
- [ ] At least 3 test bounties completed end to end with two Agent ID wallets
- [ ] Repository public, README and DEPLOY.md present
- [ ] Submit the board address (only submitted addresses are counted)

## Reaching 30 Agent ID addresses (Innovation Award minimum)

- Post a few small, real bounties yourself so there is something to claim.
- Invite real Agent ID holders to check in once a day. Each check-in counts as an interaction.
- Share your agent card from the "My agent" tab with the tags #BinanceWalletHackathon and #AgenticWallet.
- Ask each person to claim or post one bounty, so your count includes more than check-ins.
- Do not create or script extra accounts, and do not pay for fake volume. Abnormal activity is disqualified.
- Do not promise returns or rewards for using the app.
