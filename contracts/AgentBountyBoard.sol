// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Minimal balance interface for the non-transferable Agent ID collection.
interface IAgentId {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title AgentBountyBoard
 * @notice Ownerless, Agent-ID-gated bounty escrow and daily participation tracking.
 * @dev Owner permissions: none
 * Intended network: chainId 56. Expected Agent ID constructor argument:
 * 0x60b9262456de011f7d15a54cdd8c48baaa8b022f. Neither is enforced on-chain.
 * The constructor permanently selects both external contracts; there is no admin,
 * upgrade, pause, fee, rescue, or arbitrary withdrawal functionality.
 * Rewards use raw payment-token units; no decimals are assumed. Deposits must
 * increase the escrow balance by exactly the reward. Fee-on-transfer, rebasing,
 * and otherwise balance-changing tokens are not supported. Token behavior must
 * remain compatible for the lifetime of every escrow; unsolicited tokens cannot
 * be recovered. Agent ownership is checked only on posting, claiming and check-in,
 * so losing an Agent ID does not prevent an existing participant from settling.
 * A poster can reject submitted work only during the 7-day review window. Once it
 * elapses, rejection is blocked and the worker can collect the reward.
 * A worker who releases, times out on, or is rejected from a bounty cannot claim that
 * same bounty again, so claims cannot be renewed to block a poster's cancellation.
 * Reputation is a soft signal: an Agent ID holder cannot be prevented from
 * running two identities, including posting and completing their own work through them.
 */
contract AgentBountyBoard is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status { Open, Claimed, Submitted, Paid, Cancelled }

    struct Bounty {
        address poster;
        address worker;
        uint128 reward;
        uint64 claimDeadline;
        uint64 submittedAt;
        Status status;
        uint8 category;
        string title;
        string details;
        string proof;
    }

    struct CheckInRecord {
        uint256 lastDay;
        uint256 streak;
        uint256 total;
    }

    /// @dev Stored privately per address; counts and amounts use checked arithmetic.
    struct Reputation {
        uint32 posted;
        uint32 completed;
        uint128 earned;
        uint128 spent;
    }

    /// @notice Reputation and participation snapshot; streak is the active streak today.
    struct Profile {
        address user;
        uint32 posted;
        uint32 completed;
        uint128 earned;
        uint128 spent;
        uint256 streak;
        uint256 totalCheckIns;
        uint256 lastCheckInDay;
    }

    uint256 public constant REVIEW_WINDOW = 7 days;
    uint64 public constant MIN_CLAIM_WINDOW = 1 hours;
    uint64 public constant MAX_CLAIM_WINDOW = 30 days;
    /// @notice Highest supported category; categories range from zero through five inclusive.
    uint8 public constant MAX_CATEGORY = 5;

    address public immutable agentId;
    IERC20 public immutable paymentToken;

    Bounty[] private _bounties;
    mapping(uint256 id => uint64 window) private _claimWindows;
    mapping(address user => CheckInRecord record) private _checkIns;
    mapping(address user => Reputation reputation) private _reputations;
    address[] private _participants;
    mapping(address => bool) private _known;
    /// @dev Workers who released, timed out on, or were rejected from a bounty cannot re-claim it.
    mapping(uint256 id => mapping(address worker => bool barred)) private _barred;

    /// @notice Lifetime rewards paid to workers, in raw payment-token units.
    uint256 public totalPaidOut;
    /// @notice Sum of rewards of all Open, Claimed and Submitted bounties, excluding unsolicited tokens.
    uint256 public activeEscrow;

    error ZeroAddress();
    error NotAgentIdHolder();
    error InvalidBountyId(uint256 id);
    error InvalidReward();
    error InvalidClaimWindow(uint64 claimWindow);
    error InvalidCategory(uint8 category);
    error TitleTooLong();
    error DetailsTooLong();
    error ProofTooLong();
    error UnexpectedStatus(Status expected, Status actual);
    error CannotClaimOwnBounty();
    error WorkerBarred(uint256 id, address worker);
    error NotPoster();
    error NotWorker();
    error ClaimStillActive(uint64 claimDeadline);
    error ClaimDeadlinePassed(uint64 claimDeadline);
    error ReviewWindowActive(uint256 availableAt);
    error ReviewWindowElapsed(uint256 endedAt);
    error IncorrectDepositAmount();
    error AlreadyCheckedIn(uint256 day);
    error TimestampOverflow();

    event BountyPosted(
        uint256 indexed id,
        address indexed poster,
        uint128 reward,
        uint64 claimWindow,
        uint8 category,
        string title,
        string details
    );
    event BountyClaimed(uint256 indexed id, address indexed worker, uint64 claimDeadline);
    event ClaimReleased(uint256 indexed id, address indexed worker, address indexed releasedBy);
    event WorkSubmitted(uint256 indexed id, address indexed worker, uint64 submittedAt, string proof);
    event BountyPaid(uint256 indexed id, address indexed worker, uint128 reward, bool afterReviewWindow);
    event WorkRejected(uint256 indexed id, address indexed poster, address indexed worker);
    event BountyCancelled(uint256 indexed id, address indexed poster, uint128 reward);
    event CheckedIn(address indexed user, uint256 indexed day, uint256 streak);

    /// @notice Restricts new participation to addresses holding at least one Agent ID.
    modifier onlyAgentHolder() {
        if (IAgentId(agentId).balanceOf(msg.sender) == 0) revert NotAgentIdHolder();
        _;
    }

    /// @param agentId_ Agent ID collection; expected collection is documented above.
    /// @param paymentToken_ ERC-20 used for all rewards, denominated in its raw units.
    constructor(address agentId_, address paymentToken_) {
        if (agentId_ == address(0) || paymentToken_ == address(0)) revert ZeroAddress();
        agentId = agentId_;
        paymentToken = IERC20(paymentToken_);
    }

    /**
     * @notice Escrows a reward and creates an open bounty. Approve this contract first.
     * @param title Display title, at most 80 bytes (not characters).
     * @param details Description, at most 500 bytes.
     * @param reward Positive reward in raw payment-token units.
     * @param claimWindow Time allowed after each claim, inclusive range [1 hour, 30 days].
     * @param category Category identifier, inclusive range [0, MAX_CATEGORY].
     * @return id Zero-based, permanently assigned bounty identifier.
     */
    function postBounty(string calldata title, string calldata details, uint128 reward, uint64 claimWindow, uint8 category)
        external nonReentrant onlyAgentHolder returns (uint256 id)
    {
        if (reward == 0) revert InvalidReward();
        if (claimWindow < MIN_CLAIM_WINDOW || claimWindow > MAX_CLAIM_WINDOW) {
            revert InvalidClaimWindow(claimWindow);
        }
        if (category > MAX_CATEGORY) revert InvalidCategory(category);
        if (bytes(title).length > 80) revert TitleTooLong();
        if (bytes(details).length > 500) revert DetailsTooLong();

        id = _bounties.length;
        _bounties.push(Bounty({
            poster: msg.sender,
            worker: address(0),
            reward: reward,
            claimDeadline: 0,
            submittedAt: 0,
            status: Status.Open,
            category: category,
            title: title,
            details: details,
            proof: ""
        }));
        _claimWindows[id] = claimWindow;
        _register(msg.sender);
        _reputations[msg.sender].posted += 1;
        activeEscrow += reward;

        uint256 beforeBalance = paymentToken.balanceOf(address(this));
        paymentToken.safeTransferFrom(msg.sender, address(this), reward);
        uint256 afterBalance = paymentToken.balanceOf(address(this));
        if (afterBalance < beforeBalance || afterBalance - beforeBalance != uint256(reward)) {
            revert IncorrectDepositAmount();
        }
        emit BountyPosted(id, msg.sender, reward, claimWindow, category, title, details);
    }

    /// @notice Claims an open bounty; its poster cannot also be its worker.
    function claimBounty(uint256 id) external nonReentrant onlyAgentHolder {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Open);
        if (msg.sender == bounty.poster) revert CannotClaimOwnBounty();
        if (_barred[id][msg.sender]) revert WorkerBarred(id, msg.sender);
        uint256 deadline = block.timestamp + uint256(_claimWindows[id]);
        if (deadline > type(uint64).max) revert TimestampOverflow();
        bounty.worker = msg.sender;
        bounty.status = Status.Claimed;
        bounty.claimDeadline = uint64(deadline);
        _register(msg.sender);
        emit BountyClaimed(id, msg.sender, bounty.claimDeadline);
    }

    /// @notice Worker may drop a claim at any time; others may release strictly after its deadline.
    function releaseClaim(uint256 id) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Claimed);
        if (msg.sender != bounty.worker && block.timestamp <= bounty.claimDeadline) {
            revert ClaimStillActive(bounty.claimDeadline);
        }
        address worker = bounty.worker;
        _reopen(id, bounty);
        emit ClaimReleased(id, worker, msg.sender);
    }

    /// @notice Worker submits up to 500 bytes of proof, no later than the claim deadline.
    function submitWork(uint256 id, string calldata proof) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Claimed);
        if (msg.sender != bounty.worker) revert NotWorker();
        if (block.timestamp > bounty.claimDeadline) revert ClaimDeadlinePassed(bounty.claimDeadline);
        if (bytes(proof).length > 500) revert ProofTooLong();
        if (block.timestamp > type(uint64).max) revert TimestampOverflow();
        bounty.status = Status.Submitted;
        bounty.submittedAt = uint64(block.timestamp);
        bounty.proof = proof;
        emit WorkSubmitted(id, msg.sender, bounty.submittedAt, proof);
    }

    /// @notice Poster approves submitted work and pays the worker the escrowed reward.
    function approveWork(uint256 id) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Submitted);
        if (msg.sender != bounty.poster) revert NotPoster();
        _pay(id, bounty, false);
    }

    /// @notice Poster rejects submitted work (only before the review window ends) and reopens the bounty without withdrawing escrow.
    /// @dev Clears all previous claim and submission data, retaining the original claim window.
    function rejectWork(uint256 id) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Submitted);
        if (msg.sender != bounty.poster) revert NotPoster();
        uint256 reviewEnds = uint256(bounty.submittedAt) + REVIEW_WINDOW;
        if (block.timestamp >= reviewEnds) revert ReviewWindowElapsed(reviewEnds);
        address worker = bounty.worker;
        _reopen(id, bounty);
        emit WorkRejected(id, msg.sender, worker);
    }

    /// @notice Worker can collect seven days after submission if it remains submitted.
    function claimAfterReviewWindow(uint256 id) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Submitted);
        if (msg.sender != bounty.worker) revert NotWorker();
        uint256 availableAt = uint256(bounty.submittedAt) + REVIEW_WINDOW;
        if (block.timestamp < availableAt) revert ReviewWindowActive(availableAt);
        _pay(id, bounty, true);
    }

    /// @notice Poster cancels only an open bounty and receives its escrow back.
    function cancelBounty(uint256 id) external nonReentrant {
        Bounty storage bounty = _bounty(id);
        _requireStatus(bounty, Status.Open);
        if (msg.sender != bounty.poster) revert NotPoster();
        bounty.status = Status.Cancelled;
        activeEscrow -= bounty.reward;
        paymentToken.safeTransfer(bounty.poster, bounty.reward);
        emit BountyCancelled(id, bounty.poster, bounty.reward);
    }

    /// @notice Records one check-in per UTC day, extending or restarting a consecutive-day streak.
    /// @dev Total count distinguishes a never-used address from an address checked in on day zero.
    function checkIn() external nonReentrant onlyAgentHolder {
        uint256 day = block.timestamp / 1 days;
        CheckInRecord storage record = _checkIns[msg.sender];
        if (record.total != 0 && record.lastDay == day) revert AlreadyCheckedIn(day);
        record.streak = record.total != 0 && day == record.lastDay + 1 ? record.streak + 1 : 1;
        record.lastDay = day;
        record.total += 1;
        _register(msg.sender);
        emit CheckedIn(msg.sender, day, record.streak);
    }

    /// @notice Number of bounties ever created, including paid and cancelled entries.
    function bountyCount() external view returns (uint256) {
        return _bounties.length;
    }

    /// @notice Number of unique addresses that have posted, claimed or checked in successfully.
    function participantCount() external view returns (uint256) {
        return _participants.length;
    }

    /// @notice Returns a bounty by its zero-based identifier; unknown identifiers revert.
    function getBounty(uint256 id) external view returns (Bounty memory) {
        return _bounty(id);
    }

    /// @notice Returns bounties in ascending identifier order, clipping to the available range.
    /// @dev Returns an empty array for limit zero or offset beyond the last entry.
    /// The first result's ID is offset. Callers should choose small limits for RPC response sizes.
    function getBounties(uint256 offset, uint256 limit) external view returns (Bounty[] memory page) {
        uint256 count = _bounties.length;
        if (offset >= count || limit == 0) return new Bounty[](0);
        uint256 size = count - offset;
        if (limit < size) size = limit;
        page = new Bounty[](size);
        for (uint256 i; i < size; ++i) {
            page[i] = _bounties[offset + i];
        }
    }

    /// @notice Returns an address's reputation and check-in profile, even if not registered.
    /// @dev Reputation is a soft signal, not proof of unique identity or independent work.
    /// Streak is zero if the last check-in was more than one UTC day before today.
    function getProfile(address user) public view returns (Profile memory) {
        Reputation storage reputation = _reputations[user];
        CheckInRecord storage record = _checkIns[user];
        uint256 today = block.timestamp / 1 days;
        uint256 activeStreak = today > record.lastDay && today - record.lastDay > 1 ? 0 : record.streak;
        return Profile({
            user: user,
            posted: reputation.posted,
            completed: reputation.completed,
            earned: reputation.earned,
            spent: reputation.spent,
            streak: activeStreak,
            totalCheckIns: record.total,
            lastCheckInDay: record.lastDay
        });
    }

    /// @notice Returns profiles in first-participation order, clipping to the available range.
    /// @dev Returns an empty array for limit zero or offset beyond the last participant.
    /// Callers should choose small limits for RPC response sizes.
    function getProfiles(uint256 offset, uint256 limit) external view returns (Profile[] memory page) {
        uint256 count = _participants.length;
        if (offset >= count || limit == 0) return new Profile[](0);
        uint256 size = count - offset;
        if (limit < size) size = limit;
        page = new Profile[](size);
        for (uint256 i; i < size; ++i) {
            page[i] = getProfile(_participants[offset + i]);
        }
    }

    /// @notice Returns the last recorded UTC day, recorded streak and lifetime check-in count.
    /// @dev Streak is the value at last check-in; it resets on the next check-in after a missed day.
    function checkInStatus(address user) external view returns (uint256 lastDay, uint256 streak, uint256 total) {
        CheckInRecord storage record = _checkIns[user];
        return (record.lastDay, record.streak, record.total);
    }

    /// @dev Registers each participant once, preserving first-participation order.
    function _register(address user) private {
        if (!_known[user]) {
            _known[user] = true;
            _participants.push(user);
        }
    }

    function _bounty(uint256 id) private view returns (Bounty storage bounty) {
        if (id >= _bounties.length) revert InvalidBountyId(id);
        return _bounties[id];
    }

    function _requireStatus(Bounty storage bounty, Status expected) private view {
        if (bounty.status != expected) revert UnexpectedStatus(expected, bounty.status);
    }

    function _reopen(uint256 id, Bounty storage bounty) private {
        _barred[id][bounty.worker] = true;
        bounty.status = Status.Open;
        bounty.worker = address(0);
        bounty.claimDeadline = 0;
        bounty.submittedAt = 0;
        delete bounty.proof;
    }

    function _pay(uint256 id, Bounty storage bounty, bool afterReviewWindow) private {
        bounty.status = Status.Paid;
        Reputation storage workerReputation = _reputations[bounty.worker];
        workerReputation.completed += 1;
        workerReputation.earned += bounty.reward;
        _reputations[bounty.poster].spent += bounty.reward;
        totalPaidOut += bounty.reward;
        activeEscrow -= bounty.reward;
        paymentToken.safeTransfer(bounty.worker, bounty.reward);
        emit BountyPaid(id, bounty.worker, bounty.reward, afterReviewWindow);
    }
}
