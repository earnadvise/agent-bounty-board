// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AgentBountyBoard} from "../AgentBountyBoard.sol";

/// @dev Mock Agent ID collection with a settable balanceOf.
contract MockAgentId {
    mapping(address => uint256) public balanceOf;

    function setBalance(address account, uint256 value) external {
        balanceOf[account] = value;
    }
}

/// @dev 18-decimal mock stablecoin (BNB Chain USDC style).
contract MockToken is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Burns 1% of every transfer between two non-zero accounts (unsupported by the board).
contract FeeToken is ERC20 {
    constructor() ERC20("Fee Token", "FEE") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            uint256 fee = value / 100;
            super._update(from, address(0), fee);
            value -= fee;
        }
        super._update(from, to, value);
    }
}

abstract contract AgentBountyBoardTestBase is Test {
    AgentBountyBoard internal board;
    MockToken internal token;
    MockAgentId internal agent;

    address internal poster = makeAddr("poster");
    address internal worker = makeAddr("worker");
    address internal worker2 = makeAddr("worker2");
    address internal outsider = makeAddr("outsider"); // no Agent ID

    uint256 internal constant T0 = 19675 days; // start of a UTC day
    uint128 internal constant REWARD = 100e18;
    uint64 internal constant WINDOW = 1 days;
    uint256 internal constant REVIEW = 7 days;

    function setUp() public virtual {
        vm.warp(T0);
        token = new MockToken();
        agent = new MockAgentId();
        board = new AgentBountyBoard(address(agent), address(token));

        agent.setBalance(poster, 1);
        agent.setBalance(worker, 1);
        agent.setBalance(worker2, 2);

        token.mint(poster, 1_000_000e18);
        vm.prank(poster);
        token.approve(address(board), type(uint256).max);
    }

    // ---- helpers ----
    function _post() internal returns (uint256 id) {
        return _post(REWARD, WINDOW);
    }

    function _post(uint128 reward, uint64 window) internal returns (uint256 id) {
        return _postCat(reward, window, 0);
    }

    function _postCat(uint128 reward, uint64 window, uint8 category) internal returns (uint256 id) {
        vm.prank(poster);
        id = board.postBounty("title", "details", reward, window, category);
    }

    function _checkInAs(address who) internal {
        vm.prank(who);
        board.checkIn();
    }

    function _approve(uint256 id) internal {
        vm.prank(poster);
        board.approveWork(id);
    }

    function _release(uint256 id, address who) internal {
        vm.prank(who);
        board.releaseClaim(id);
    }

    function _claim(uint256 id, address who) internal {
        vm.prank(who);
        board.claimBounty(id);
    }

    function _submit(uint256 id, address who) internal {
        vm.prank(who);
        board.submitWork(id, "ipfs://proof");
    }

    /// @dev post + claim by `worker`
    function _postClaimed() internal returns (uint256 id) {
        id = _post();
        _claim(id, worker);
    }

    /// @dev post + claim + submit by `worker`
    function _postSubmitted() internal returns (uint256 id) {
        id = _postClaimed();
        _submit(id, worker);
    }

    function _status(uint256 id) internal view returns (AgentBountyBoard.Status) {
        return board.getBounty(id).status;
    }

    function _str(uint256 len) internal pure returns (string memory) {
        return string(new bytes(len));
    }
}
