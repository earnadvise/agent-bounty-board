// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardBarredTest is AgentBountyBoardTestBase {
    function _barredErr(uint256 id, address who) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(AgentBountyBoard.WorkerBarred.selector, id, who);
    }

    function _expectBarred(uint256 id, address who) internal {
        vm.expectRevert(_barredErr(id, who));
        vm.prank(who);
        board.claimBounty(id);
    }

    // ---------- the three barring paths ----------
    function test_Barred_WorkerWhoReleasedCannotReclaim() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        _expectBarred(id, worker);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Open));
    }

    function test_Barred_WorkerReleasedAfterTimeoutCannotReclaim() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 1);
        _release(id, outsider); // third party releases after deadline
        _expectBarred(id, worker);
    }

    function test_Barred_WorkerWhoReleasedAfterDeadlineThemselvesCannotReclaim() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 100);
        _release(id, worker);
        _expectBarred(id, worker);
    }

    function test_Barred_RejectedWorkerCannotReclaim() public {
        uint256 id = _postSubmitted();
        vm.prank(poster);
        board.rejectWork(id);
        _expectBarred(id, worker);
    }

    function test_Barred_BarOutlastsTime() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        vm.warp(T0 + 365 days);
        _expectBarred(id, worker);
    }

    // ---------- scope of the bar ----------
    function test_Barred_WorkerCanClaimOtherBounties() public {
        uint256 id = _postClaimed();
        uint256 other = _post();
        _release(id, worker);
        _claim(other, worker);
        assertEq(board.getBounty(other).worker, worker);
        _expectBarred(id, worker);
    }

    function test_Barred_OtherWorkersCanClaimSameBounty() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        _claim(id, worker2);
        assertEq(board.getBounty(id).worker, worker2);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Claimed));
    }

    function test_Barred_SecondWorkerAlsoBarredAfterRelease() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        _claim(id, worker2);
        _release(id, worker2);
        _expectBarred(id, worker);
        _expectBarred(id, worker2);
    }

    function test_Barred_OtherWorkerCompletesAfterBarredOneLeft() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        _claim(id, worker2);
        _submit(id, worker2);
        _approve(id);
        assertEq(token.balanceOf(worker2), REWARD);
        assertEq(board.getProfile(worker).completed, 0);
        assertEq(board.getProfile(worker2).completed, 1);
    }

    function test_Barred_BarChecksStatusFirst() public {
        // Claimed bounty: status error takes precedence over bar check.
        uint256 id = _postClaimed();
        _release(id, worker);
        _claim(id, worker2);
        vm.expectRevert(
            abi.encodeWithSelector(
                AgentBountyBoard.UnexpectedStatus.selector,
                AgentBountyBoard.Status.Open,
                AgentBountyBoard.Status.Claimed
            )
        );
        vm.prank(worker);
        board.claimBounty(id);
    }

    function test_Barred_PosterCheckPrecedesBar() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        vm.expectRevert(AgentBountyBoard.CannotClaimOwnBounty.selector);
        vm.prank(poster);
        board.claimBounty(id);
    }

    function test_Barred_AgentIdCheckPrecedesBar() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        agent.setBalance(worker, 0);
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        vm.prank(worker);
        board.claimBounty(id);
    }

    function test_Barred_RevertedClaimDoesNotChangeState() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        uint256 participants = board.participantCount();
        _expectBarred(id, worker);
        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(b.worker, address(0));
        assertEq(b.claimDeadline, 0);
        assertEq(board.participantCount(), participants);
    }

    // ---------- poster cancellation after the barred worker leaves ----------
    function test_Barred_PosterCanCancelAfterWorkerReleases() public {
        uint256 id = _postClaimed();
        uint256 before = token.balanceOf(poster);
        _release(id, worker);
        // barred worker cannot renew claim to block cancellation
        _expectBarred(id, worker);
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyCancelled(id, poster, REWARD);
        vm.prank(poster);
        board.cancelBounty(id);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Cancelled));
        assertEq(token.balanceOf(poster), before + REWARD);
        assertEq(board.activeEscrow(), 0);
    }

    function test_Barred_PosterCanCancelAfterTimeoutRelease() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 1);
        _release(id, outsider);
        _expectBarred(id, worker);
        vm.prank(poster);
        board.cancelBounty(id);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Cancelled));
    }

    function test_Barred_PosterCanCancelAfterReject() public {
        uint256 id = _postSubmitted();
        vm.prank(poster);
        board.rejectWork(id);
        _expectBarred(id, worker);
        vm.prank(poster);
        board.cancelBounty(id);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Cancelled));
    }

    function test_Barred_ClaimingCancelledBountyStillStatusError() public {
        uint256 id = _postClaimed();
        _release(id, worker);
        vm.prank(poster);
        board.cancelBounty(id);
        vm.expectRevert(
            abi.encodeWithSelector(
                AgentBountyBoard.UnexpectedStatus.selector,
                AgentBountyBoard.Status.Open,
                AgentBountyBoard.Status.Cancelled
            )
        );
        vm.prank(worker);
        board.claimBounty(id);
    }

    // ---------- fuzz ----------
    function testFuzz_Barred_ReleaseAtAnyTimeBarsWorker(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 90 days));
        uint256 id = _postClaimed();
        skip(elapsed);
        _release(id, worker);
        _expectBarred(id, worker);
        _claim(id, worker2); // bar is per worker
    }
}
