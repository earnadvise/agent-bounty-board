// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardReputationTest is AgentBountyBoardTestBase {
    uint256 internal constant DAY0 = T0 / 1 days;

    // ---------- registry ----------
    function test_Participants_EmptyInitially() public view {
        assertEq(board.participantCount(), 0);
        assertEq(board.getProfiles(0, 10).length, 0);
    }

    function test_Participants_PostRegistersPoster() public {
        _post();
        assertEq(board.participantCount(), 1);
        assertEq(board.getProfiles(0, 10)[0].user, poster);
    }

    function test_Participants_ClaimRegistersWorker() public {
        uint256 id = _post();
        _claim(id, worker);
        assertEq(board.participantCount(), 2);
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(0, 10);
        assertEq(ps[0].user, poster);
        assertEq(ps[1].user, worker);
    }

    function test_Participants_CheckInRegisters() public {
        _checkInAs(worker2);
        assertEq(board.participantCount(), 1);
        assertEq(board.getProfiles(0, 1)[0].user, worker2);
    }

    function test_Participants_RegisteredOnlyOnce() public {
        _post();
        _post();
        uint256 id = _post();
        _checkInAs(poster);
        _claim(id, worker);
        _release(id, worker);
        _claim(1, worker);
        vm.warp(T0 + 1 days);
        _checkInAs(poster);
        _checkInAs(worker);
        assertEq(board.participantCount(), 2);
    }

    function test_Participants_FailedActionsDoNotRegister() public {
        uint256 id = _post();
        vm.prank(outsider);
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        board.claimBounty(id);
        vm.prank(outsider);
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        board.checkIn();
        vm.prank(worker);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.InvalidBountyId.selector, 99));
        board.claimBounty(99);
        assertEq(board.participantCount(), 1, "only poster");
    }

    function test_Participants_ThirdPartyReleaseDoesNotRegister() public {
        uint256 id = _postClaimed();
        vm.warp(T0 + WINDOW + 1);
        _release(id, outsider); // outsider has no Agent ID and must not be registered
        assertEq(board.participantCount(), 2);
        assertEq(board.getProfile(outsider).posted, 0);
    }

    // ---------- getProfile defaults ----------
    function test_GetProfile_UnknownAddressReturnsZeros() public view {
        AgentBountyBoard.Profile memory p = board.getProfile(outsider);
        assertEq(p.user, outsider);
        assertEq(p.posted, 0);
        assertEq(p.completed, 0);
        assertEq(p.earned, 0);
        assertEq(p.spent, 0);
        assertEq(p.streak, 0);
        assertEq(p.totalCheckIns, 0);
        assertEq(p.lastCheckInDay, 0);
    }

    // ---------- posted / completed / earned / spent ----------
    function test_Reputation_PostedIncrementsPerPost() public {
        _post();
        _post();
        _post();
        assertEq(board.getProfile(poster).posted, 3);
        assertEq(board.getProfile(worker).posted, 0);
    }

    function test_Reputation_ApproveCreditsWorkerAndDebitsPoster() public {
        uint256 id = _postSubmitted();
        _approve(id);
        AgentBountyBoard.Profile memory w = board.getProfile(worker);
        AgentBountyBoard.Profile memory p = board.getProfile(poster);
        assertEq(w.completed, 1);
        assertEq(w.earned, REWARD);
        assertEq(w.spent, 0);
        assertEq(w.posted, 0);
        assertEq(p.spent, REWARD);
        assertEq(p.completed, 0);
        assertEq(p.earned, 0);
        assertEq(p.posted, 1);
    }

    function test_Reputation_ClaimAfterReviewWindowCredits() public {
        uint256 id = _postSubmitted();
        vm.warp(T0 + REVIEW);
        vm.prank(worker);
        board.claimAfterReviewWindow(id);
        assertEq(board.getProfile(worker).completed, 1);
        assertEq(board.getProfile(worker).earned, REWARD);
        assertEq(board.getProfile(poster).spent, REWARD);
    }

    function test_Reputation_AccumulatesAcrossBounties() public {
        uint256 a = _post(10e18, WINDOW);
        uint256 b = _post(25e18, WINDOW);
        _claim(a, worker);
        _claim(b, worker);
        _submit(a, worker);
        _submit(b, worker);
        _approve(a);
        _approve(b);
        AgentBountyBoard.Profile memory w = board.getProfile(worker);
        assertEq(w.completed, 2);
        assertEq(w.earned, 35e18);
        assertEq(board.getProfile(poster).spent, 35e18);
        assertEq(board.totalPaidOut(), 35e18);
    }

    function test_Reputation_UnaffectedByRejectReleaseCancel() public {
        uint256 id = _postSubmitted();
        vm.prank(poster);
        board.rejectWork(id);
        _claim(id, worker2);
        _release(id, worker2);
        vm.prank(poster);
        board.cancelBounty(id);
        AgentBountyBoard.Profile memory w = board.getProfile(worker);
        AgentBountyBoard.Profile memory p = board.getProfile(poster);
        assertEq(w.completed, 0);
        assertEq(w.earned, 0);
        assertEq(p.spent, 0);
        assertEq(p.posted, 1);
        assertEq(board.totalPaidOut(), 0);
    }

    function test_Reputation_SelfDealingViaTwoIdentitiesCountsAsNormal() public {
        // documented soft signal: a second identity can complete the poster's work
        address alt = makeAddr("alt");
        agent.setBalance(alt, 1);
        uint256 id = _post();
        _claim(id, alt);
        _submit(id, alt);
        _approve(id);
        assertEq(board.getProfile(alt).completed, 1);
    }

    // ---------- check-in profile / active streak ----------
    function test_Profile_CheckInFields() public {
        _checkInAs(worker);
        AgentBountyBoard.Profile memory p = board.getProfile(worker);
        assertEq(p.streak, 1);
        assertEq(p.totalCheckIns, 1);
        assertEq(p.lastCheckInDay, DAY0);
    }

    function test_Profile_StreakActiveSameDayAndNextDay() public {
        _checkInAs(worker);
        vm.warp(T0 + 1 days);
        _checkInAs(worker);
        assertEq(board.getProfile(worker).streak, 2);
        vm.warp(T0 + 2 days + 23 hours); // one UTC day after last check-in: still active
        assertEq(board.getProfile(worker).streak, 2);
    }

    function test_Profile_StreakZeroAfterMoreThanOneDayGap() public {
        _checkInAs(worker);
        vm.warp(T0 + 1 days);
        _checkInAs(worker);
        vm.warp(T0 + 3 days); // last = day+1, today = day+3
        AgentBountyBoard.Profile memory p = board.getProfile(worker);
        assertEq(p.streak, 0);
        assertEq(p.totalCheckIns, 2);
        assertEq(p.lastCheckInDay, DAY0 + 1);
        (, uint256 raw,) = board.checkInStatus(worker);
        assertEq(raw, 2, "recorded streak untouched");
    }

    function test_Profile_StreakRestartsAfterLapse() public {
        _checkInAs(worker);
        vm.warp(T0 + 5 days);
        assertEq(board.getProfile(worker).streak, 0);
        _checkInAs(worker);
        assertEq(board.getProfile(worker).streak, 1);
        assertEq(board.getProfile(worker).totalCheckIns, 2);
    }

    function test_Profile_NeverCheckedInStreakZero() public {
        vm.warp(T0 + 100 days);
        assertEq(board.getProfile(worker).streak, 0);
    }

    // ---------- getProfiles pagination ----------
    function _seedFive() internal {
        // order: poster (post), worker, worker2 (claims), then 2 check-in-only users
        uint256 a = _post();
        uint256 b = _post();
        _claim(a, worker);
        _claim(b, worker2);
        address c = makeAddr("c");
        address d = makeAddr("d");
        agent.setBalance(c, 1);
        agent.setBalance(d, 1);
        _checkInAs(c);
        _checkInAs(d);
    }

    function test_GetProfiles_FirstRegistrationOrder() public {
        _seedFive();
        assertEq(board.participantCount(), 5);
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(0, 10);
        assertEq(ps.length, 5);
        assertEq(ps[0].user, poster);
        assertEq(ps[1].user, worker);
        assertEq(ps[2].user, worker2);
        assertEq(ps[3].user, makeAddr("c"));
        assertEq(ps[4].user, makeAddr("d"));
        assertEq(ps[0].posted, 2);
    }

    function test_GetProfiles_MiddlePage() public {
        _seedFive();
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(1, 2);
        assertEq(ps.length, 2);
        assertEq(ps[0].user, worker);
        assertEq(ps[1].user, worker2);
    }

    function test_GetProfiles_LimitClipped() public {
        _seedFive();
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(3, 100);
        assertEq(ps.length, 2);
        assertEq(ps[1].user, makeAddr("d"));
    }

    function test_GetProfiles_OffsetAtOrBeyondCountEmpty() public {
        _seedFive();
        assertEq(board.getProfiles(5, 1).length, 0);
        assertEq(board.getProfiles(type(uint256).max, 1).length, 0);
    }

    function test_GetProfiles_ZeroLimitEmpty() public {
        _seedFive();
        assertEq(board.getProfiles(0, 0).length, 0);
    }

    function test_GetProfiles_HugeLimitNoOverflow() public {
        _seedFive();
        assertEq(board.getProfiles(0, type(uint256).max).length, 5);
        assertEq(board.getProfiles(type(uint256).max, type(uint256).max).length, 0);
    }

    function test_GetProfiles_ReflectsActiveStreakAndReputation() public {
        uint256 id = _postSubmitted();
        _approve(id);
        _checkInAs(worker);
        vm.warp(T0 + 3 days);
        AgentBountyBoard.Profile[] memory ps = board.getProfiles(0, 10);
        assertEq(ps[1].user, worker);
        assertEq(ps[1].completed, 1);
        assertEq(ps[1].streak, 0, "lapsed");
        assertEq(ps[1].totalCheckIns, 1);
    }
}
