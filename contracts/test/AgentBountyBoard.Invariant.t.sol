// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentBountyBoardTestBase, MockToken, MockAgentId} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

/// @dev Drives bounded random actions through a small set of Agent ID holders.
contract BountyBoardHandler is Test {
    AgentBountyBoard public board;
    MockToken public token;
    address[] public actors;

    uint256 public posts;
    uint256 public approvals;
    uint256 public cancels;

    constructor(AgentBountyBoard board_, MockToken token_, MockAgentId agent_) {
        board = board_;
        token = token_;
        for (uint256 i; i < 3; ++i) {
            address a = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
            actors.push(a);
            agent_.setBalance(a, 1);
            vm.prank(a);
            token.approve(address(board_), type(uint256).max);
        }
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function _id(uint256 seed) internal view returns (uint256) {
        uint256 n = board.bountyCount();
        return n == 0 ? 0 : seed % n;
    }

    function post(uint256 actorSeed, uint128 reward, uint64 window, uint8 category) external {
        reward = uint128(bound(reward, 1, 1e24));
        window = uint64(bound(window, 1 hours, 30 days));
        category = uint8(bound(category, 0, 5));
        address a = _actor(actorSeed);
        token.mint(a, reward);
        vm.prank(a);
        board.postBounty("t", "d", reward, window, category);
        posts++;
    }

    function checkIn(uint256 actorSeed) external {
        vm.prank(_actor(actorSeed));
        try board.checkIn() {} catch {}
    }

    function claim(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.claimBounty(_id(idSeed)) {} catch {}
    }

    function release(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.releaseClaim(_id(idSeed)) {} catch {}
    }

    function submit(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.submitWork(_id(idSeed), "proof") {} catch {}
    }

    function approve(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.approveWork(_id(idSeed)) {
            approvals++;
        } catch {}
    }

    function reject(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.rejectWork(_id(idSeed)) {} catch {}
    }

    function claimAfterWindow(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.claimAfterReviewWindow(_id(idSeed)) {} catch {}
    }

    function cancel(uint256 actorSeed, uint256 idSeed) external {
        vm.prank(_actor(actorSeed));
        try board.cancelBounty(_id(idSeed)) {
            cancels++;
        } catch {}
    }

    function warp(uint256 secs) external {
        vm.warp(block.timestamp + bound(secs, 0, 10 days));
    }
}

contract AgentBountyBoardInvariantTest is AgentBountyBoardTestBase {
    BountyBoardHandler internal handler;

    function setUp() public override {
        super.setUp();
        handler = new BountyBoardHandler(board, token, agent);
        targetContract(address(handler));
    }

    /// PROPERTY: escrow balance == sum of rewards of Open / Claimed / Submitted bounties.
    function invariant_BalanceEqualsLiveRewards() public view {
        AgentBountyBoard.Bounty[] memory all = board.getBounties(0, board.bountyCount());
        uint256 sum;
        for (uint256 i; i < all.length; ++i) {
            AgentBountyBoard.Status s = all[i].status;
            if (
                s == AgentBountyBoard.Status.Open || s == AgentBountyBoard.Status.Claimed
                    || s == AgentBountyBoard.Status.Submitted
            ) {
                sum += all[i].reward;
            }
        }
        assertEq(token.balanceOf(address(board)), sum);
    }

    /// PROPERTY: activeEscrow == token balance == sum of live rewards; totalPaidOut == sum of Paid rewards.
    function invariant_CountersMatchBountiesAndBalance() public view {
        AgentBountyBoard.Bounty[] memory all = board.getBounties(0, board.bountyCount());
        uint256 live;
        uint256 paid;
        for (uint256 i; i < all.length; ++i) {
            AgentBountyBoard.Status s = all[i].status;
            if (s == AgentBountyBoard.Status.Paid) {
                paid += all[i].reward;
            } else if (s != AgentBountyBoard.Status.Cancelled) {
                live += all[i].reward;
            }
        }
        assertEq(board.activeEscrow(), token.balanceOf(address(board)), "escrow != balance");
        assertEq(board.activeEscrow(), live, "escrow != live rewards");
        assertEq(board.totalPaidOut(), paid, "paidOut != paid rewards");
    }

    /// PROPERTY: reputation totals are consistent with bounty state; categories stay in range.
    function invariant_ReputationConsistent() public view {
        uint256 n = board.participantCount();
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(0, n);
        assertEq(ps.length, n);
        uint256 posted;
        uint256 completed;
        uint256 earned;
        uint256 spent;
        for (uint256 i; i < ps.length; ++i) {
            posted += ps[i].posted;
            completed += ps[i].completed;
            earned += ps[i].earned;
            spent += ps[i].spent;
            for (uint256 j; j < i; ++j) {
                assertTrue(ps[i].user != ps[j].user, "duplicate participant");
            }
        }
        AgentBountyBoard.Bounty[] memory all = board.getBounties(0, board.bountyCount());
        uint256 paidCount;
        for (uint256 i; i < all.length; ++i) {
            if (all[i].status == AgentBountyBoard.Status.Paid) ++paidCount;
            assertLe(all[i].category, board.MAX_CATEGORY());
        }
        assertEq(posted, all.length, "posted");
        assertEq(completed, paidCount, "completed");
        assertEq(earned, board.totalPaidOut(), "earned");
        assertEq(spent, board.totalPaidOut(), "spent");
    }
}
