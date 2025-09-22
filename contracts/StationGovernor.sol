// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/**
 * @title StationGovernor
 * @notice Minimal per-station Governor using StationShare (ERC20Votes) as voting token.
 * No timelock here; add TimelockController if/when you need queued execution.
 */
contract StationGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    constructor(
        IVotes token
    )
        Governor("StationGovernor")
        GovernorSettings(
            /* votingDelay   */ 1, // 1 block (tune as needed)
            /* votingPeriod  */ 45818, // ~1 week (tune for your chain)
            /* proposalThreshold */ 0
        )
        GovernorVotes(token)
        GovernorVotesQuorumFraction(4) // 4% quorum (example)
    {}

    // ---- Required overrides for OZ v5 multiple inheritance ----

    function quorum(
        uint256 blockNumber
    )
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    // These are only needed when combining with Timelock or custom executors:
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
