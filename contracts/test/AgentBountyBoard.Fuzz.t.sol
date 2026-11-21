// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardFuzzTest is AgentBountyBoardTestBase {
    function testFuzz_PostEscrowsExactRewardAndStoresWindow(uint128 reward, uint64 window) public {
        reward = uint128(bound(reward, 1, type(uint128).max));
        window = uint64(bound(window, 1 hours, 30 days));
        token.mint(poster, reward);

        uint256 posterBefore = token.balanceOf(poster);
        uint256 id = _post(reward, window);

        assertEq(token.balanceOf(address(board)), reward);
        assertEq(token.balanceOf(poster), posterBefore - reward);
        assertEq(board.getBounty(id).reward, reward);

        // claim deadline = claim time + the configured window
        _claim(id, worker);
        assertEq(board.getBounty(id).claimDeadline, uint64(block.timestamp + window));
    }

    function testFuzz_FullCycleWorkerReceivesExactReward(uint128 reward, uint64 window, uint32 submitDelay) public {
        reward = uint128(bound(reward, 1, type(uint128).max));
        window = uint64(bound(window, 1 hours, 30 days));
        submitDelay = uint32(bound(submitDelay, 0, window));
        token.mint(poster, reward);

        uint256 id = _post(reward, window);
        _claim(id, worker);
        skip(submitDelay);
        _submit(id, worker);
        vm.prank(poster);
        board.approveWork(id);

        assertEq(token.balanceOf(worker), reward);
        assertEq(token.balanceOf(address(board)), 0);
    }

    function testFuzz_CancelRefundsExactReward(uint128 reward, uint64 window) public {
        reward = uint128(bound(reward, 1, type(uint128).max));
        window = uint64(bound(window, 1 hours, 30 days));
        token.mint(poster, reward);
        uint256 before = token.balanceOf(poster);

        uint256 id = _post(reward, window);
        vm.prank(poster);
        board.cancelBounty(id);

        assertEq(token.balanceOf(poster), before);
        assertEq(token.balanceOf(address(board)), 0);
    }

    function testFuzz_WindowTooShortReverts(uint64 window) public {
        window = uint64(bound(window, 0, 1 hours - 1));
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidClaimWindow.selector, window));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, window, 0);
    }

    function testFuzz_WindowTooLongReverts(uint64 window) public {
        window = uint64(bound(window, 30 days + 1, type(uint64).max));
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidClaimWindow.selector, window));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, window, 0);
    }

    function testFuzz_ValidCategoryStoredAndEmitted(uint8 category) public {
        category = uint8(bound(category, 0, 5));
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.BountyPosted(0, poster, REWARD, WINDOW, category, "title", "details");
        uint256 id = _postCat(REWARD, WINDOW, category);
        assertEq(board.getBounty(id).category, category);
    }

    function testFuzz_InvalidCategoryReverts(uint8 category) public {
        category = uint8(bound(category, 6, type(uint8).max));
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidCategory.selector, category));
        vm.prank(poster);
        board.postBounty("t", "d", REWARD, WINDOW, category);
        assertEq(board.bountyCount(), 0);
    }

    function testFuzz_ReputationAfterPayment(uint128 reward, uint8 n) public {
        reward = uint128(bound(reward, 1, 1e30));
        n = uint8(bound(n, 1, 6));
        token.mint(poster, uint256(reward) * n);
        for (uint256 i; i < n; ++i) {
            uint256 id = _post(reward, WINDOW);
            _claim(id, worker);
            _submit(id, worker);
            _approve(id);
        }
        AgentBountyBoard.Profile memory w = board.getProfile(worker);
        AgentBountyBoard.Profile memory p = board.getProfile(poster);
        assertEq(w.completed, n);
        assertEq(w.earned, uint256(reward) * n);
        assertEq(p.posted, n);
        assertEq(p.spent, uint256(reward) * n);
        assertEq(board.totalPaidOut(), uint256(reward) * n);
        assertEq(board.activeEscrow(), 0);
        assertEq(board.participantCount(), 2);
    }

    function testFuzz_ActiveStreakZeroAfterGap(uint32 gapDays) public {
        gapDays = uint32(bound(gapDays, 0, 1000));
        _checkInAs(worker);
        vm.warp(T0 + uint256(gapDays) * 1 days + 1 hours);
        AgentBountyBoard.Profile memory p = board.getProfile(worker);
        assertEq(p.streak, gapDays <= 1 ? 1 : 0);
        assertEq(p.totalCheckIns, 1);
        assertEq(p.lastCheckInDay, T0 / 1 days);
    }

    function testFuzz_GetProfilesClipping(uint8 count, uint8 offset, uint8 limit) public {
        count = uint8(bound(count, 0, 12));
        for (uint256 i; i < count; ++i) {
            address a = address(uint160(0x1000 + i));
            agent.setBalance(a, 1);
            _checkInAs(a);
        }
        assertEq(board.participantCount(), count);
        AgentBountyBoard.Profile[] memory page = board.getProfiles(offset, limit);
        uint256 expected = offset >= count || limit == 0 ? 0 : (count - offset < limit ? count - offset : limit);
        assertEq(page.length, expected);
        for (uint256 i; i < page.length; ++i) {
            assertEq(page[i].user, address(uint160(0x1000 + offset + i)));
        }
    }

    function testFuzz_SubmitAfterDeadlineReverts(uint64 window, uint32 lateBy) public {
        window = uint64(bound(window, 1 hours, 30 days));
        lateBy = uint32(bound(lateBy, 1, 365 days));
        uint256 id = _post(REWARD, window);
        _claim(id, worker);
        skip(uint256(window) + lateBy);
        vm.expectRevert(
            abi.encodeWithSelector(AgentBountyBoard.ClaimDeadlinePassed.selector, uint64(T0 + window))
        );
        vm.prank(worker);
        board.submitWork(id, "p");
    }

    function testFuzz_ReleaseByThirdPartyOnlyAfterDeadline(uint64 window, uint32 elapsed) public {
        window = uint64(bound(window, 1 hours, 30 days));
        elapsed = uint32(bound(elapsed, 0, 60 days));
        uint256 id = _post(REWARD, window);
        _claim(id, worker);
        skip(elapsed);
        vm.prank(outsider);
        if (elapsed <= window) {
            vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ClaimStillActive.selector, uint64(T0 + window)));
            board.releaseClaim(id);
        } else {
            board.releaseClaim(id);
            assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Open));
        }
    }

    function testFuzz_ReviewWindowGatesRejectAndWorkerClaim(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 30 days));
        uint256 id = _postSubmitted();
        skip(elapsed);
        if (elapsed < REVIEW) {
            vm.prank(worker);
            vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ReviewWindowActive.selector, T0 + REVIEW));
            board.claimAfterReviewWindow(id);
            vm.prank(poster);
            board.rejectWork(id);
            assertEq(uint8(_status(id)), uint8(AgentBountyBoard.Status.Open));
        } else {
            vm.prank(poster);
            vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.ReviewWindowElapsed.selector, T0 + REVIEW));
            board.rejectWork(id);
            vm.prank(worker);
            board.claimAfterReviewWindow(id);
            assertEq(token.balanceOf(worker), REWARD);
        }
    }

    function testFuzz_CheckInStreakModel(uint8[12] memory gaps) public {
        uint256 expectedStreak;
        uint256 day = 100;
        for (uint256 i; i < gaps.length; ++i) {
            uint256 gap = bound(gaps[i], 1, 4); // days since the previous check-in
            day += gap;
            vm.warp(day * 1 days + (uint256(gaps[i]) * 997) % 1 days);
            expectedStreak = (i != 0 && gap == 1) ? expectedStreak + 1 : 1;
            vm.prank(worker);
            board.checkIn();
            (uint256 lastDay, uint256 streak, uint256 total) = board.checkInStatus(worker);
            assertEq(lastDay, day);
            assertEq(streak, expectedStreak);
            assertEq(total, i + 1);
        }
    }
}
