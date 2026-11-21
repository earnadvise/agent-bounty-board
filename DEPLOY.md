# Deploying Agent Bounty Board to BNB Chain

Warning: Transactions on mainnet involve real funds and, once submitted, are irreversible. You deploy and operate this contract yourself, from your own wallet. Review the code, test it, and consider an independent professional audit before you put real funds in it.

## What you need

- A wallet with BNB for gas, used only for deploying. Keep its key in an environment variable, never in a file you commit.
- The Agent ID address (from the hackathon rules): `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
- The ERC-20 you want bounties paid in on BNB Chain. Confirm its address from Circle's official USDC documentation and check it on BscScan before using it. Note that USDC on BNB Chain may use 18 decimals, the app reads decimals from the token, so this is handled.
- A BscScan API key (for source verification, required by the hackathon).

## 1. Test first

```bash
forge test
```

All tests must pass.

## 2. Deploy

The BNB Chain RPC used by this project is listed in `src/onchain-facts.ts` (chain id 56). Export it and your values, then deploy:

```bash
export BSC_RPC=<rpc url for chain 56 from src/onchain-facts.ts>
export PRIVATE_KEY=<deployer key, never commit this>
export AGENT_ID=0x60b9262456de011f7d15a54cdd8c48baaa8b022f
export PAYMENT_TOKEN=<verified ERC-20 address on BNB Chain>

forge create contracts/AgentBountyBoard.sol:AgentBountyBoard \
  --rpc-url $BSC_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args $AGENT_ID $PAYMENT_TOKEN
```

Copy the `Deployed to:` address.

## 3. Verify on BscScan

```bash
export BOARD=<deployed address>
export BSCSCAN_API_KEY=<your key>

forge verify-contract $BOARD contracts/AgentBountyBoard.sol:AgentBountyBoard \
  --chain 56 \
  --verifier etherscan \
  --etherscan-api-key $BSCSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" $AGENT_ID $PAYMENT_TOKEN) \
  --compiler-version 0.8.28 \
  --num-of-optimizations 200 \
  --watch
```

## Alternative: deploy and verify with Remix (no local tools)

1. Open https://remix.ethereum.org and create `AgentBountyBoard.flat.sol`. Paste the contents of `docs/AgentBountyBoard.flat.sol`.
2. Compiler tab: version 0.8.28, EVM version `cancun`, enable optimization with 200 runs. Compile `AgentBountyBoard`.
3. Connect your wallet to BNB Chain (chain id 56), then in Deploy and Run choose "Injected Provider".
4. Enter the two constructor arguments (Agent ID address, payment token address), double check both, and deploy. Confirm in your wallet.
5. On BscScan open the new contract, choose Verify and Publish, select "Solidity (Single file)", compiler 0.8.28, optimization Yes with 200 runs, EVM version cancun, then paste the same flat file. Enter the constructor arguments ABI-encoded if asked (BscScan can usually detect them).

## 4. Point the app at it

Add this line to `.env` and restart the dev server:

```
VITE_BOUNTY_BOARD_ADDRESS=<deployed address>
```

## 5. Submit

- Project name and website (deploy the app from the Integrations menu)
- Contract address: the board address (only submitted contracts are counted)
- Agent ID usage: every post, claim and check-in requires the caller to hold an Agent ID, checked onchain
- Disclose owner permissions: none (the contract has no owner, pause, fee, upgrade or withdraw function)

## Getting traction

Only interactions from Agent ID holders count. Invite real holders to check in daily and post small bounties. Do not use scripted or bulk accounts, the rules disqualify volume manipulation.
