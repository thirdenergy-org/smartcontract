// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./StationShare.sol";

/**
 * @title CrowdfundStation
 * @notice HBAR escrow for one station with share minting and **admin-withdraw** flow.
 * - Contribute HBAR during Funding phase; receive StationShare (scaled 1e10 to map tinybars->18d).
 * - Admin (treasury) can close funding early once goal is reached, or finalize after deadline.
 * - On success (Succeeded): treasury withdraws funds via `withdraw(amount)` / `sweepToTreasury()`.
 * - On failure (Failed): contributors can refund by burning matching shares.
 */
contract CrowdfundStation is ReentrancyGuard {
    enum Phase {
        Funding,
        Succeeded,
        Failed
    }

    // Tinybars (HBAR base unit) have 8 decimals; ERC20 has 18. Use SCALER to align voting math.
    uint256 private constant SCALER = 1e10;

    StationShare public immutable share;
    address public immutable treasury;
    uint256 public immutable goalTinybars;
    uint64 public immutable deadline; // unix seconds

    Phase public phase;
    uint256 public totalRaised; // tinybars

    event Contributed(address indexed user, uint256 tinybars, uint256 shares);
    event FundingClosed(uint256 totalRaised); // early close → Succeeded
    event Finalized(Phase outcome, uint256 totalRaised); // post-deadline finalize
    event Withdrawn(address indexed treasury, uint256 tinybars);
    event Refunded(address indexed user, uint256 tinybars);

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Crowdfund: not treasury");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address treasury_,
        uint256 goalTinybars_,
        uint64 deadlineSec_
    ) {
        require(treasury_ != address(0), "treasury=0");
        require(deadlineSec_ > block.timestamp, "bad deadline");
        share = new StationShare(name, symbol);
        treasury = treasury_;
        goalTinybars = goalTinybars_;
        deadline = deadlineSec_;
        phase = Phase.Funding;
    }

    /// @notice Contribute HBAR; mints StationShare scaled from tinybars to 18 decimals.
    function contribute() external payable nonReentrant {
        require(phase == Phase.Funding, "Crowdfund: closed");
        require(block.timestamp <= deadline, "Crowdfund: deadline passed");
        require(msg.value > 0, "Crowdfund: zero value");

        uint256 sharesToMint = msg.value * SCALER;
        totalRaised += msg.value;

        share.mint(msg.sender, sharesToMint);
        emit Contributed(msg.sender, msg.value, sharesToMint);

        // (optional) auto-close when goal reached; comment out if you prefer manual close
        // if (totalRaised >= goalTinybars) _closeFunding();
    }

    /// @notice Treasury may close early once goal is met (before deadline).
    function closeFunding() external onlyTreasury {
        require(phase == Phase.Funding, "Crowdfund: not funding");
        require(totalRaised >= goalTinybars, "Crowdfund: goal not met");
        _closeFunding();
    }

    function _closeFunding() internal {
        phase = Phase.Succeeded;
        emit FundingClosed(totalRaised);
    }

    /// @notice Anyone can finalize after the deadline.
    /// Success if goal met (sets Succeeded), else Failed. No auto-transfer.
    function finalize() external {
        require(phase == Phase.Funding, "Crowdfund: already closed");
        require(block.timestamp > deadline, "Crowdfund: not ended");
        phase = (totalRaised >= goalTinybars) ? Phase.Succeeded : Phase.Failed;
        emit Finalized(phase, totalRaised);
    }

    /// @notice Treasury withdraws any amount (partial or full) after success.
    function withdraw(
        uint256 tinybarsAmount
    ) external onlyTreasury nonReentrant {
        require(phase == Phase.Succeeded, "Crowdfund: not succeeded");
        require(tinybarsAmount > 0, "Crowdfund: zero");
        (bool ok, ) = payable(treasury).call{value: tinybarsAmount}("");
        require(ok, "Crowdfund: withdraw failed");
        emit Withdrawn(treasury, tinybarsAmount);
    }

    /// @notice Treasury convenience to withdraw full balance.
    function sweepToTreasury() external onlyTreasury nonReentrant {
        require(phase == Phase.Succeeded, "Crowdfund: not succeeded");
        uint256 bal = address(this).balance;
        (bool ok, ) = payable(treasury).call{value: bal}("");
        require(ok, "Crowdfund: sweep failed");
        emit Withdrawn(treasury, bal);
    }

    /// @notice Refund path only if campaign failed.
    /// Caller burns shares equal to the tinybars they are claiming back (scaled).
    function refund(uint256 tinybarsAmount) external nonReentrant {
        require(phase == Phase.Failed, "Crowdfund: not failed");
        require(tinybarsAmount > 0, "Crowdfund: zero");
        uint256 sharesToBurn = tinybarsAmount * SCALER;

        // Effects
        share.burnFrom(msg.sender, sharesToBurn);

        // Interaction
        (bool ok, ) = payable(msg.sender).call{value: tinybarsAmount}("");
        require(ok, "Crowdfund: refund failed");

        emit Refunded(msg.sender, tinybarsAmount);
    }

    /// @dev Helpers
    function status()
        external
        view
        returns (Phase, uint256 raised, uint64 endTs, uint256 goal)
    {
        return (phase, totalRaised, deadline, goalTinybars);
    }

    receive() external payable {
        revert("use contribute()");
    }
}
