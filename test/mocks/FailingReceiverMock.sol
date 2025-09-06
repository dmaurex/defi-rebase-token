// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vault} from "src/Vault.sol";

// Mock contract for testing Vault__RedeemFailed error
contract FailingReceiverMock {
    error FailingReceiverMock__MockFailure();

    // Contract will fail when receiving ETH
    receive() external payable {
        revert FailingReceiverMock__MockFailure();
    }

    function redeemFromVault(Vault vault, uint256 amount) external {
        vault.redeem(amount);
    }
}
