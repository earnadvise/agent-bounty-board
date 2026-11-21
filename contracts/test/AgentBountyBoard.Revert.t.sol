// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardRevertTest is AgentBountyBoardTestBase {
    AgentBountyBoard.Status internal constant S_OPEN = AgentBountyBoard.Status.Open;
    AgentBountyBoard.Status internal constant S_CLAIMED = AgentBountyBoard.Status.Claimed;
    AgentBountyBoard.Status internal constant S_SUBMITTED = AgentBountyBoard.Status.Submitted;
    AgentBountyBoard.Status internal constant S_PAID = AgentBountyBoard.Status.Paid;
    AgentBountyBoard.Status internal constant S_CANCELLED = AgentBountyBoard.Status.Cancelled;

    function _unexpected(AgentBountyBoard.Status expected, AgentBountyBoard.Status actual)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(AgentBountyBoard.UnexpectedStatus.selector, expected, actual);
    }

    // ---------- postBounty ----------
    function test_RevertPost_NotAgentHolder() public {
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        vm.prank(outsider);
        board.postBounty("t", "d", REWARD, WINDOW, 0);
    }

    function test_RevertPost_AgentIdBalanceRemovedBlocksPosting() public {
        agent.setBalance(poster, 0);
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, 0);
    }

    function test_RevertPost_ZeroReward() public {
        vm.expectRevert(AgentBountyBoard.InvalidReward.selector);
        vm.prank(poster);
        board.postBounty("t", "d", 0, WINDOW, 0);
    }

    function test_RevertPost_WindowTooShort() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidClaimWindow.selector, uint64(1 hours - 1)));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, 1 hours - 1, 0);
    }

    function test_RevertPost_WindowTooLong() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidClaimWindow.selector, uint64(30 days + 1)));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, 30 days + 1, 0);
    }

    function test_RevertPost_InvalidCategory() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, uint8(6)));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, 6);
    }

    function test_RevertPost_InvalidCategoryMaxUint8() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, uint8(255)));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, 255);
    }

    function test_RevertPost_InvalidCategoryDoesNotRegisterOrEscrow() public {
        vm.prank(poster);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, uint8(6)));
        board.postBounty("t", "d", REWARD, WINDOW, 6);
        assertEq(board.participantCount(), 0);
        assertEq(board.activeEscrow(), 0);
        assertEq(board.bountyCount(), 0);
    }

    function test_RevertPost_CategoryBoundaryMaxCategoryAccepted() public {
        assertEq(board.MAX_CATEGORY(), 5);
        uint256 id = _postCat(REWARD, WINDOW, board.MAX_CATEGORY());
        assertEq(board.getBounty(id).category, 5);
    }

    function test_RevertPost_InvalidCategoryJustAboveMax() public {
        uint8 above = board.MAX_CATEGORY() + 1;
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, above));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, above);
    }

    function test_RevertPost_ZeroRewardPrecedesCategory() public {
        vm.expectRevert(AgentBountyBoard.InvalidReward.selector);
        vm.prank(poster);
        board.postBounty("t", "d", 0, WINDOW, 9);
    }

    function test_RevertPost_WindowPrecedesCategory() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidClaimWindow.selector, uint64(1)));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, 1, 9);
    }

    function test_RevertPost_CategoryPrecedesTitleLength() public {
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, uint8(9)));
        vm.prank(poster);
        board.postBounty(_str(81), "d", REWARD, WINDOW, 9);
    }

    function test_RevertPost_AgentHolderCheckPrecedesCategory() public {
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        vm.prank(outsider);
        board.postBounty("t", "d", REWARD, WINDOW, 9);
    }

    function test_RevertPost_TitleTooLong() public {
        string memory t = _str(81);
        vm.expectRevert(AgentBountyBoard.TitleTooLong.selector);
        vm.prank(poster);
        board.postBounty(t, "d", REWARD, WINDOW, 0);
    }

    function test_RevertPost_DetailsTooLong() public {
        string memory d = _str(501);
        vm.expectRevert(AgentBountyBoard.DetailsTooLong.selector);
        vm.prank(poster);
        board.postBounty("t", d, REWARD, WINDOW, 0);
    }

    function test_RevertPost_InsufficientAllowance() public {
        vm.prank(poster);
        token.approve(address(board), 0);
        vm.expectRevert();
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, 0);
    }

    // ---------- invalid ids ----------
    function test_RevertInvalidBountyId_AllIdFunctions() public {
        bytes memory err = abi.encodeWithSelector(AgentBountyBoard.InvalidBountyId.selector, 0);
        vm.expectRevert(err);
        board.getBounty(0);
        vm.expectRevert(err);
        vm.prank(worker);
        board.claimBounty(0);
        vm.expectRevert(err);
        vm.prank(worker);
        board.releaseClaim(0);
        vm.expectRevert(err);
        vm.prank(worker);
        board.submitWork(0, "p");
        vm.expectRevert(err);
        vm.prank(poster);
        board.approveWork(0);
        vm.expectRevert(err);
        vm.prank(poster);
        board.rejectWork(0);
        vm.expectRevert(err);
        vm.prank(worker);
        board.claimAfterReviewWindow(0);
        vm.expectRevert(err);
        vm.prank(poster);
        board.cancelBounty(0);
    }

    // ---------- claimBounty ----------
    function test_RevertClaim_NotAgentHolder() public {
        uint256 id = _post();
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        vm.prank(outsider);
        board.claimBounty(id);
    }

    function test_RevertClaim_OwnBounty() public {
        uint256 id = _post();
        vm.expectRevert(AgentBountyBoard.CannotClaimOwnBounty.selector);
        vm.prank(poster);
        board.claimBounty(id);
    }

    function test_RevertClaim_AlreadyClaimed() public {
        uint256 id = _postClaimed();
        vm.expectRevert(_unexpected(S_OPEN, S_CLAIMED));
        vm.prank(worker2);
        board.claimBounty(id);
    }

    function test_RevertClaim_Cancelled() public {
        uint256 id = _post();
        vm.prank(poster);
        board.cancelBounty(id);
        vm.expectRevert(_unexpected(S_OPEN, S_CANCELLED));
        vm.prank(worker);
        board.claimBounty(id);
    }

    // ---------- releaseClaim ----------
    function test_RevertRelease_WrongStatusOpen() public {
        uint256 id = _post();
        vm.expectRevert(_unexpected(S_CLAIMED, S_OPEN));
        vm.prank(worker);
        board.releaseClaim(id);
    }

    function test_RevertRelease_WrongStatusSubmitted() public {
        uint256 id = _postSubmitted();
        vm.expectRevert(_unexpected(S_CLAIMED, S_SUBMITTED));
        vm.prank(worker);
        board.releaseClaim(id);
    }

    function test_RevertRelease_NonWorkerBeforeDeadline() public {
        uint256 id = _postClaimed();
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ClaimStillActive.selector, uint64(T0 + WINDOW)));
        vm.prank(worker2);
        board.releaseClaim(id);
    }

    function test_RevertRelease_NonWorkerExactlyAtDeadline() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ClaimStillActive.selector, uint64(T0 + WINDOW)));
        vm.prank(worker2);
        board.releaseClaim(id);
    }

    function test_Release_WorkerCanReleaseAfterDeadlineToo() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 100);
        vm.prank(worker);
        board.releaseClaim(id);
        assertEq(uint8(_status(id)), uint8(S_OPEN));
    }

    // ---------- submitWork ----------
    function test_RevertSubmit_WrongStatusOpen() public {
        uint256 id = _post();
        vm.expectRevert(_unexpected(S_CLAIMED, S_OPEN));
        vm.prank(worker);
        board.submitWork(id, "p");
    }

    function test_RevertSubmit_NotWorker() public {
        uint256 id = _postClaimed();
        vm.expectRevert(AgentBountyBoard.NotWorker.selector);
        vm.prank(worker2);
        board.submitWork(id, "p");
    }

    function test_RevertSubmit_PosterIsNotWorker() public {
        uint256 id = _postClaimed();
        vm.expectRevert(AgentBountyBoard.NotWorker.selector);
        vm.prank(poster);
        board.submitWork(id, "p");
    }

    function test_RevertSubmit_ClaimDeadlinePassed() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 1);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ClaimDeadlinePassed.selector, uint64(T0 + WINDOW)));
        vm.prank(worker);
        board.submitWork(id, "p");
    }

    function test_RevertSubmit_ProofTooLong() public {
        uint256 id = _postClaimed();
        string memory p = _str(501);
        vm.expectRevert(AgentBountyBoard.ProofTooLong.selector);
        vm.prank(worker);
        board.submitWork(id, p);
    }

    function test_RevertSubmit_AlreadySubmitted() public {
        uint256 id = _postSubmitted();
        vm.expectRevert(_unexpected(S_CLAIMED, S_SUBMITTED));
        vm.prank(worker);
        board.submitWork(id, "again");
    }

    // ---------- approveWork ----------
    function test_RevertApprove_WrongStatusClaimed() public {
        uint256 id = _postClaimed();
        vm.expectRevert(_unexpected(S_SUBMITTED, S_CLAIMED));
        vm.prank(poster);
        board.approveWork(id);
    }

    function test_RevertApprove_NotPoster() public {
        uint256 id = _postSubmitted();
        vm.expectRevert(AgentBountyBoard.NotPoster.selector);
        vm.prank(worker);
        board.approveWork(id);
    }

    function test_RevertApprove_DoublePay() public {
        uint256 id = _postSubmitted();
        vm.startPrank(poster);
        board.approveWork(id);
        vm.expectRevert(_unexpected(S_SUBMITTED, S_PAID));
        board.approveWork(id);
        vm.stopPrank();
    }

    // ---------- rejectWork ----------
    function test_RevertReject_WrongStatus() public {
        uint256 id = _postClaimed();
        vm.expectRevert(_unexpected(S_SUBMITTED, S_CLAIMED));
        vm.prank(poster);
        board.rejectWork(id);
    }

    function test_RevertReject_NotPoster() public {
        uint256 id = _postSubmitted();
        vm.expectRevert(AgentBountyBoard.NotPoster.selector);
        vm.prank(worker);
        board.rejectWork(id);
    }

    function test_RevertReject_ExactlyAtReviewWindowEnd() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ReviewWindowElapsed.selector, T0 + REVIEW));
        vm.prank(poster);
        board.rejectWork(id);
    }

    function test_RevertReject_AfterSevenDays() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW + 1 days);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ReviewWindowElapsed.selector, T0 + REVIEW));
        vm.prank(poster);
        board.rejectWork(id);
    }

    // ---------- claimAfterReviewWindow ----------
    function test_RevertClaimAfter_WrongStatus() public {
        uint256 id = _postClaimed();
        vm.expectRevert(_unexpected(S_SUBMITTED, S_CLAIMED));
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
    }

    function test_RevertClaimAfter_NotWorker() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.expectRevert(AgentBountyBoard.NotWorker.selector);
        vm.prank(poster);
        board.claimAfterReviewWindow(id);
    }

    function test_RevertClaimAfter_ReviewWindowActive() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW - 1);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ReviewWindowActive.selector, T0 + REVIEW));
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
    }

    function test_RevertClaimAfter_DoubleClaim() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.startPrank(worker);
        board.claimAfterReviewWindow(id);
        vm.expectRevert(_unexpected(S_SUBMITTED, S_PAID));
        board.claimAfterReviewWindow(id);
        vm.stopPrank();
    }

    function test_ReviewWindowMeasuredFromSubmission_NotClaim() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + 10 hours);
        _submit(id, worker);
        vm.warp(T0 + 10 hours + REVIEW - 1);
        vm.expectRevert(
            abi.encodeWithSelector(AgentBountyBoard.ReviewWindowActive.selector, T0 + 10 hours + REVIEW)
        );
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
    }

    // ---------- cancelBounty ----------
    function test_RevertCancel_NotPoster() public {
        uint256 id = _post();
        vm.expectRevert(AgentBountyBoard.NotPoster.selector);
        vm.prank(worker);
        board.cancelBounty(id);
    }

    function test_RevertCancel_WhenClaimed() public {
        uint256 id = _postClaimed();
        vm.expectRevert(_unexpected(S_OPEN, S_CLAIMED));
        vm.prank(poster);
        board.cancelBounty(id);
    }

    function test_RevertCancel_Twice() public {
        uint256 id = _post();
        vm.startPrank(poster);
        board.cancelBounty(id);
        vm.expectRevert(_unexpected(S_OPEN, S_CANCELLED));
        board.cancelBounty(id);
        vm.stopPrank();
    }
}
