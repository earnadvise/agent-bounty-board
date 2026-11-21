// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AgentBountyBoardTestBase} from "./AgentBountyBoard.Base.t.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

contract AgentBountyBoardCheckInTest is AgentBountyBoardTestBase {
    uint256 internal constant DAY0 = T0 / 1 days;

    function _checkIn(address who) internal {
        vm.prank(who);
        board.checkIn();
    }

    function test_CheckIn_FirstTimeStartsStreakAtOne() public {
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.CheckedIn(worker, DAY0, 1);
        _checkIn(worker);
        (uint256 lastDay, uint256 streak, uint256 total) = board.checkInStatus(worker);
        assertEq(lastDay, DAY0);
        assertEq(streak, 1);
        assertEq(total, 1);
    }

    function test_CheckIn_UnusedAddressHasZeroStatus() public view {
        (uint256 a, uint256 b, uint256 c) = board.checkInStatus(worker);
        assertEq(a, 0);
        assertEq(b, 0);
        assertEq(c, 0);
    }

    function test_RevertCheckIn_NotAgentHolder() public {
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        _checkIn(outsider);
    }

    function test_RevertCheckIn_TwiceSameUtcDay() public {
        _checkIn(worker);
        vm.warp(T0 + 1 days - 1); // last second of the same UTC day
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.AlreadyCheckedIn.selector, DAY0));
        _checkIn(worker);
    }

    function test_CheckIn_SecondsAcrossMidnightCountsAsNewDay() public {
        vm.warp(T0 + 1 days - 1);
        _checkIn(worker);
        vm.warp(T0 + 1 days); // one second later, next UTC day
        _checkIn(worker);
        (uint256 lastDay, uint256 streak, uint256 total) = board.checkInStatus(worker);
        assertEq(lastDay, DAY0 + 1);
        assertEq(streak, 2);
        assertEq(total, 2);
    }

    function test_CheckIn_StreakContinuesOnConsecutiveDays() public {
        for (uint256 i; i < 5; ++i) {
            vm.warp(T0 + i * 1 days + 12 hours);
            vm.expectEmit(true, true, false, true, address(board));
            emit AgentBountyBoard.CheckedIn(worker, DAY0 + i, i + 1);
            _checkIn(worker);
        }
        (, uint256 streak, uint256 total) = board.checkInStatus(worker);
        assertEq(streak, 5);
        assertEq(total, 5);
    }

    function test_CheckIn_StreakResetsAfterMissedDay() public {
        _checkIn(worker);
        vm.warp(T0 + 1 days);
        _checkIn(worker);
        vm.warp(T0 + 3 days); // day 2 missed
        vm.expectEmit(true, true, false, true, address(board));
        emit AgentBountyBoard.CheckedIn(worker, DAY0 + 3, 1);
        _checkIn(worker);
        (uint256 lastDay, uint256 streak, uint256 total) = board.checkInStatus(worker);
        assertEq(lastDay, DAY0 + 3);
        assertEq(streak, 1);
        assertEq(total, 3, "lifetime total keeps counting");
    }

    function test_CheckIn_UsersAreIndependent() public {
        _checkIn(worker);
        _checkIn(worker2);
        vm.warp(T0 + 1 days);
        _checkIn(worker);
        (, uint256 s1,) = board.checkInStatus(worker);
        (, uint256 s2,) = board.checkInStatus(worker2);
        assertEq(s1, 2);
        assertEq(s2, 1);
    }

    function test_CheckIn_DayZeroIsDistinguishedFromNeverUsed() public {
        vm.warp(0);
        _checkIn(worker);
        vm.expectRevert(abi.encodeWithSelector(AgentBountyBoard.AlreadyCheckedIn.selector, 0));
        _checkIn(worker);
        vm.warp(1 days);
        _checkIn(worker);
        (uint256 lastDay, uint256 streak, uint256 total) = board.checkInStatus(worker);
        assertEq(lastDay, 1);
        assertEq(streak, 2);
        assertEq(total, 2);
    }

    function test_CheckIn_LosingAgentIdAfterwardsBlocksNextCheckIn() public {
        _checkIn(worker);
        agent.setBalance(worker, 0);
        vm.warp(T0 + 1 days);
        vm.expectRevert(AgentBountyBoard.NotAgentIdHolder.selector);
        _checkIn(worker);
    }

    // ---------- pagination / views ----------
    function _postMany(uint256 n) internal {
        for (uint256 i; i < n; ++i) {
            _post(uint128(1e18 * (i + 1)), WINDOW);
        }
    }

    function test_GetBounties_FirstPage() public {
        _postMany(5);
        AgentBountyBoard.Bounty[] memory page = board.getBounties(0, 2);
        assertEq(page.length, 2);
        assertEq(page[0].reward, 1e18);
        assertEq(page[1].reward, 2e18);
    }

    function test_GetBounties_MiddlePageStartsAtOffset() public {
        _postMany(5);
        AgentBountyBoard.Bounty[] memory page = board.getBounties(2, 2);
        assertEq(page.length, 2);
        assertEq(page[0].reward, 3e18);
        assertEq(page[1].reward, 4e18);
    }

    function test_GetBounties_LimitClippedToAvailable() public {
        _postMany(5);
        AgentBountyBoard.Bounty[] memory page = board.getBounties(3, 100);
        assertEq(page.length, 2);
        assertEq(page[1].reward, 5e18);
    }

    function test_GetBounties_OffsetAtOrBeyondCountIsEmpty() public {
        _postMany(5);
        assertEq(board.getBounties(5, 1).length, 0);
        assertEq(board.getBounties(1000, 1).length, 0);
    }

    function test_GetBounties_ZeroLimitIsEmpty() public {
        _postMany(3);
        assertEq(board.getBounties(0, 0).length, 0);
    }

    function test_GetBounties_EmptyBoard() public view {
        assertEq(board.getBounties(0, 10).length, 0);
    }

    function test_GetBounties_ReflectsStatusChanges() public {
        _postMany(2);
        vm.prank(poster);
        board.cancelBounty(0);
        AgentBountyBoard.Bounty[] memory page = board.getBounties(0, 10);
        assertEq(uint8(page[0].status), uint8(AgentBountyBoard.Status.Cancelled));
        assertEq(uint8(page[1].status), uint8(AgentBountyBoard.Status.Open));
    }

    function test_GetBounties_HugeOffsetAndLimitDoNotOverflow() public {
        _postMany(2);
        assertEq(board.getBounties(type(uint256).max, type(uint256).max).length, 0);
        assertEq(board.getBounties(0, type(uint256).max).length, 2);
    }
}
