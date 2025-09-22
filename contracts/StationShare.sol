// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title StationShare
 * @notice Per-station ERC20Votes token (voting power == balance).
 * Deployed by CrowdfundStation; CrowdfundStation is the minter.
 */
contract StationShare is ERC20, ERC20Permit, ERC20Votes {
    address public minter;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        minter = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "StationShare: not minter");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        require(msg.sender == minter, "StationShare: not minter");
        _burn(from, amount);
    }

    // -------- OpenZeppelin v5 required overrides --------

    /// Reconcile ERC20 + ERC20Votes hook (v5 uses _update for votes checkpoints)
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// Resolve duplicate Nonces (via ERC20Permit and Votes->Nonces)
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
