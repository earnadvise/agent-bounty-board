// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase, FeeToken} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardLifecycleTest is AgentBountyBoardTestBase {
    AgentBountyBoard.Status internal constant OPEN = AgentBountyBoard.Status.Open;

    // ---------- constructor ----------
    function test_Constructor_StoresImmutables() public view {
        assertEq(board.agentId(), address(agent));
        assertEq(address(board.paymentToken()), address(token));
        assertEq(board.bountyCount(), 0);
    }

    function test_Constructor_RevertsOnZeroAgentId() public {
        vm.expectRevert(AgentBountyBoard.ZeroAddress.selector);
        new AgentBountyBoard(address(0), address(token));
    }

    function test_Constructor_RevertsOnZeroToken() public {
        vm.expectRevert(AgentBountyBoard.ZeroAddress.selector);
        new AgentBountyBoard(address(agent), address(0));
    }

    // ---------- postBounty ----------
    function test_PostBounty_EscrowsRewardAndStoresBounty() public {
        uint256 posterBefore = token.balanceOf(poster);
        uint256 id = _post();
        assertEq(id, 0);
        assertEq(board.bountyCount(), 1);
        assertEq(token.balanceOf(address(board)), REWARD);
        assertEq(token.balanceOf(poster), posterBefore - REWARD);

        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(b.poster, poster);
        assertEq(b.worker, address(0));
        assertEq(b.reward, REWARD);
        assertEq(b.claimDeadline, 0);
        assertEq(b.submittedAt, 0);
        assertEq(uint8(b.status), uint8(OPEN));
        assertEq(b.title, "title");
        assertEq(b.details, "details");
        assertEq(b.proof, "");
    }

    function test_PostBounty_IdsIncrement() public {
        assertEq(_post(), 0);
        assertEq(_post(), 1);
        assertEq(_post(), 2);
    }

    function test_PostBounty_BoundaryValuesAccepted() public {
        vm.startPrank(poster);
        board.postBounty(_str(80), _str(500), 1, board.MIN_CLAIM_WINDOW(), 0);
        board.postBounty("", "", 1, board.MAX_CLAIM_WINDOW(), board.MAX_CATEGORY());
        vm.stopPrank();
        assertEq(board.bountyCount(), 2);
        assertEq(board.getBounty(1).category, 5);
    }

    function test_PostBounty_CategoryReturnedByGetBountiesAndPreservedThroughLifecycle() public {
        uint256 id = _postCat(REWARD, WINDOW, 4);
        _postCat(REWARD, WINDOW, 2);
        _claim(id, worker);
        _release(id, worker);
        _claim(id, worker2);
        _submit(id, worker2);
        _approve(id);
        AgentBountyBoard.Bounty[] memory page = board.getBounties(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0].category, 4);
        assertEq(page[1].category, 2);
        assertEq(uint8(page[0].status), uint8(AgentBountyBoard.Status.Paid));
    }

    function test_PostBounty_StoresCategory() public {
        uint256 id = _postCat(REWARD, WINDOW, 3);
        assertEq(board.getBounty(id).category, 3);
        assertEq(board.MAX_CATEGORY(), 5);
    }

    function test_PostBounty_EmitsEvent() public {
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyPosted(0, poster, REWARD, WINDOW, 4, "title", "details");
        _postCat(REWARD, WINDOW, 4);
    }

    function test_PostBounty_UpdatesActiveEscrow() public {
        _post();
        _post(7e18, WINDOW);
        assertEq(board.activeEscrow(), REWARD + 7e18);
        assertEq(board.totalPaidOut(), 0);
    }

    function test_ApproveWork_MovesEscrowToPaidOut() public {
        uint256 id = _postSubmitted();
        _post(7e18, WINDOW);
        _approve(id);
        assertEq(board.activeEscrow(), 7e18);
        assertEq(board.totalPaidOut(), REWARD);
    }

    function test_ClaimAfterReviewWindow_MovesEscrowToPaidOut() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
        assertEq(board.activeEscrow(), 0);
        assertEq(board.totalPaidOut(), REWARD);
    }

    function test_CancelBounty_DecrementsActiveEscrowOnly() public {
        uint256 id = _post();
        vm.prank(poster);
        board.cancelBounty(id);
        assertEq(board.activeEscrow(), 0);
        assertEq(board.totalPaidOut(), 0);
    }

    function test_RejectAndRelease_KeepActiveEscrow() public {
        uint256 id = _postSubmitted();
        vm.prank(poster);
        board.rejectWork(id);
        assertEq(board.activeEscrow(), REWARD);
        _claim(id, worker2);
        _release(id, worker2);
        assertEq(board.activeEscrow(), REWARD);
    }

    function test_ActiveEscrow_IgnoresUnsolicitedTokens() public {
        _post();
        token.mint(address(board), 55e18);
        assertEq(board.activeEscrow(), REWARD);
    }

    // ---------- claimBounty ----------
    function test_ClaimBounty_SetsWorkerAndDeadline() public {
        uint256 id = _post();
        _claim(id, worker);
        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(b.worker, worker);
        assertEq(b.claimDeadline, uint64(T0 + WINDOW));
        assertEq(uint8(b.status), uint8(AgentBountyBoard.Status.Claimed));
    }

    function test_ClaimBounty_EmitsEvent() public {
        uint256 id = _post();
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyClaimed(id, worker, uint64(T0 + WINDOW));
        _claim(id, worker);
    }

    // ---------- releaseClaim ----------
    function test_ReleaseClaim_ByWorkerAnytime() public {
        uint256 id = _postClaimed();
        vm.expectEmit(true, true, true, false, address(board));
        emit AgentBountyBoard.ClaimReleased(id, worker, worker);
        vm.prank(worker);
        board.releaseClaim(id);

        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(uint8(b.status), uint8(OPEN));
        assertEq(b.worker, address(0));
        assertEq(b.claimDeadline, 0);
    }

    function test_ReleaseClaim_ByAnyoneAfterDeadline() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 1);
        vm.expectEmit(true, true, true, false, address(board));
        emit AgentBountyBoard.ClaimReleased(id, worker, outsider);
        vm.prank(outsider); // does not even need an Agent ID
        board.releaseClaim(id);
        assertEq(uint8(_status(id)), uint8(OPEN));
        assertEq(board.getBounty(id).worker, address(0));
    }

    function test_ReleasedBountyCanBeReclaimedByAnother() public {
        uint256 id = _postClaimed();
        vm.prank(worker);
        board.releaseClaim(id);
        vm.warp(T0 + 5 hours);
        _claim(id, worker2);
        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(b.worker, worker2);
        assertEq(b.claimDeadline, uint64(T0 + 5 hours + WINDOW));
    }

    // ---------- submitWork ----------
    function test_SubmitWork_StoresProofAndTimestamp() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + 3 hours);
        _submit(id, worker);
        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(uint8(b.status), uint8(AgentBountyBoard.Status.Submitted));
        assertEq(b.proof, "ipfs://proof");
        assertEq(b.submittedAt, uint64(T0 + 3 hours));
    }

    function test_SubmitWork_EmitsEvent() public {
        uint256 id = _postClaimed();
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.WorkSubmitted(id, worker, uint64(T0), "ipfs://proof");
        _submit(id, worker);
    }

    function test_SubmitWork_AllowedExactlyAtDeadline() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW);
        _submit(id, worker);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Submitted));
    }

    function test_SubmitWork_ProofOf500BytesAccepted() public {
        uint256 id = _postClaimed();
        vm.prank(worker);
        board.submitWork(id, _str(500));
        assertEq(bytes(board.getBounty(id).proof).length, 500);
    }

    // ---------- approveWork ----------
    function test_ApproveWork_PaysWorker() public {
        uint256 id = _postSubmitted();
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyPaid(id, worker, REWARD, false);
        vm.prank(poster);
        board.approveWork(id);

        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Paid));
        assertEq(token.balanceOf(worker), REWARD);
        assertEq(token.balanceOf(address(board)), 0);
    }

    function test_ApproveWork_StillAllowedAfterReviewWindow() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW + 10 days);
        vm.prank(poster);
        board.approveWork(id);
        assertEq(token.balanceOf(worker), REWARD);
    }

    // ---------- rejectWork ----------
    function test_RejectWork_ReopensAndClearsClaimData() public {
        uint256 id = _postSubmitted();
        vm.expectEmit(true, true, true, false, address(board));
        emit AgentBountyBoard.WorkRejected(id, poster, worker);
        vm.prank(poster);
        board.rejectWork(id);

        AgentBountyBoard.Bounty memory b = board.getBounty(id);
        assertEq(uint8(b.status), uint8(OPEN));
        assertEq(b.worker, address(0));
        assertEq(b.claimDeadline, 0);
        assertEq(b.submittedAt, 0);
        assertEq(b.proof, "");
        assertEq(token.balanceOf(address(board)), REWARD, "escrow retained");
    }

    function test_RejectWork_AllowedOneSecondBeforeWindowEnds() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW - 1);
        vm.prank(poster);
        board.rejectWork(id);
        assertEq(uint8(_status(id)), uint8(OPEN));
    }

    function test_RejectWork_ReopenedBountyCanBeClaimedAgainWithSameWindow() public {
        uint256 id = _postSubmitted();
        vm.prank(poster);
        board.rejectWork(id);
        _claim(id, worker2);
        assertEq(board.getBounty(id).claimDeadline, uint64(T0 + WINDOW));
    }

    // ---------- claimAfterReviewWindow ----------
    function test_ClaimAfterReviewWindow_PaysWorkerAtExactBoundary() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyPaid(id, worker, REWARD, true);
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Paid));
        assertEq(token.balanceOf(worker), REWARD);
    }

    // ---------- cancelBounty ----------
    function test_CancelBounty_RefundsPoster() public {
        uint256 before = token.balanceOf(poster);
        uint256 id = _post();
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyCancelled(id, poster, REWARD);
        vm.prank(poster);
        board.cancelBounty(id);

        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Cancelled));
        assertEq(token.balanceOf(poster), before);
        assertEq(token.balanceOf(address(board)), 0);
    }

    function test_CancelBounty_AfterReleaseAndRejectWorks() public {
        uint256 id = _postSubmitted();
        vm.startPrank(poster);
        board.rejectWork(id);
        board.cancelBounty(id);
        vm.stopPrank();
        assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Cancelled));
    }

    // ---------- fee-on-transfer ----------
    function test_PostBounty_FeeOnTransferTokenRejected() public {
        FeeToken fee = new FeeToken();
        AgentBountyBoard feeBoard = new AgentBountyBoard(address(agent), address(fee));
        fee.mint(poster, 1_000e18);
        vm.startPrank(poster);
        fee.approve(address(feeBoard), type(uint256).max);
        vm.expectRevert(AgentBountyBoard.IncorrectDepositAmount.selector);
        feeBoard.postBounty("t", "d", 100e18, WINDOW, 0);
        vm.stopPrank();
        assertEq(feeBoard.bountyCount(), 0, "state rolled back");
        assertEq(feeBoard.activeEscrow(), 0);
        assertEq(feeBoard.participantCount(), 0);
    }
}
